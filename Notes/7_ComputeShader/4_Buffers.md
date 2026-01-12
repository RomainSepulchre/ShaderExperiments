# Buffers

**Links:**

- https://docs.unity3d.com/6000.3/Documentation/ScriptReference/ComputeBuffer.html
- https://www.youtube.com/watch?v=BrZ4pWwkpto
- https://catlikecoding.com/unity/tutorials/basics/compute-shaders/
- https://www.youtube.com/watch?v=9RHGLZLUuwc&list=LL2T54R7-vJmcMBzcaTL_oBw&index=3

## What is a buffer ?

When working with compute shaders its sometimes necessary to process multiple data simultaneously (ex: particles, post-processing, ray tracing, simulations). To speed up reading/writing in the memory buffer we can use two associated data types: **ComputeBuffer** and **StructuredBuffer**.

When using buffers we are able to pass huge array of data to the compute shader and process them with GPU thread instead of using the CPU.

## ComputeBuffer and StructuredBuffer

When we want to use a buffer inside a compute shader we need to a **ComputeBuffer** and a **StructuredBuffer**.

The `ComputeBuffer` is declared inside the c# script and we can fill it with the value we want to pass to the compute shader.

```c#
// Declared in the c# script that controls the compute shader

struct BufferData // Struct that define the data we store inside the compute buffer
{
    Vector3 vertices;
    Vector3 normals;
    Vector4 tangents;
};

BufferData[] bufferData; // Array of data we want to pass in the buffer
ComputeBuffer buffer; // compute buffer we will pass to the compute shader
```

The `StructuredBuffer` is the equivalent of the ComputeBuffer declared inside the compute shader. It's the variable that will store the data of the buffer inside the compute shader and we can use to access the elements stored inside the buffer.

```c#
// Declared inside the compute shader

struct BufferData
{
    float3 vertices;
    float3 normals;
    float4 tangents;
};
StructuredBuffer<BufferData> bufferData;
```

## Work with buffer data in a compute shader

In this example lets imagine we have a huge grid of cubes and we want to be able to modify their position and color.

### Declare the computeBuffer and structuredBuffer

Inside our c# script we need to declare our `ComputeBuffer` with the data we want to be able to process in the compute shader.

```c#
// (C# script)
private struct CubeData
{
    public Vector3 position;
    public Color color;
}
private CubeData[] cubesData;
private ComputeBuffer cubesDataBuffer;
```

We also need to declare its equivalent in the computer shader, the `StructuredBuffer`. Its the variable that will store the data from the computeBuffer inside the compute shader. Since we want to be able to access the result of the operations done on the data we need to declare our structured buffer as a `RWStructuredBuffer`, it the buffer equivalent of a `RWTexture`.

```c#
// (Compute shader)
struct CubeData
{
    float3 position;
    float4 color;
};

RWStructuredBuffer<CubeData> cubesData; // Use the structured buffer as output
```

### Set the compute buffer in the c# script

In our c# controller script, we need to fill *cubesData* our `CubeData[]` with the position, rotation and color value of the cubes. We consider *cubes* is a `List<GameObject>` that contains the references to all the cube gameObjects.

```c#
// (C# script)
void FillCubeData()
{
    cubesData = new Cube[cubes.Count];

    for (int i = 0; i < cubes.Count; i++)
    {
        // Get cube data
        CubeData cubeData = new CubeData();
        cubeData.position = cubes[i].transform.position;
        cubeData.color = cubes[i].GetComponent<MeshRenderer>().material.GetColor("_Color");

        // Store cube data in the CubeData[]
        cubesData[i] = cubeData;
    }
}
```

Once, our `CubeData[]` is filled we can use it to create the compute buffer. When we create a `ComputeBuffer` we need to pass 2 informations: the count (*number of element to store* in the buffer) and the stride (*size in byte of the type of element*).

The count is simply the length of `CubeData[]` and to calcualte the stride we can make the sum of the size of every variable stored inside `CubeData`. In our example the position is a `Vector3` (3 floats = `3 * sizeof(float)`) and the color is a `Color` (4 floats = `4 * sizeof(float)`).

Finally, we set the buffer data and we send the `ComputeBuffer` to the compute shader `StructuredBuffer` with `ComputeShader.SetBuffer()`.  

```c#
// (C# script)
public void UpdateCubes()
{
    int numberOfElements = cubesData.Length;

    int posSize = sizeof(float) * 3;
    int colSize = sizeof(float) * 4;
    int totalSize = posSize + colSize;

    cubesDataBuffer = new ComputeBuffer(numberOfElements, totalSize); // Create the compute buffer

    cubesDataBuffer.SetData(cubesData); // Set the data of the compute buffer

    computeShader.SetBuffer(0, "cubesData", cubesDataBuffer); // Send ComputeBuffer data to the StruturedBuffer

    ...
}
```

### Process the StructuredBuffer in the compute shader

Inside the compute shader, we can access the `StructuredBuffer` data, process it and then store the new value back in the `StructuredBuffer`.

Since we work with a 1D array to simplify the process we set the `numthreads()` to **64,1,1** because we only need to use one axis of threads.

```c#
// (Compute shader)
[numthreads(64,1,1)]
void CSMain (uint3 id : SV_DispatchThreadID)
{
    CubeData cubeData = cubesData[id.x];

    // process and assign new data
    cubeData.position = ... ;
    cubeData.color = ...;
    
    // Store the new data in the buffer
    cubesData[id.x] = cubeData;
}
```

### Apply the compute shader result

To process the data we call `Dispatch()` on the compute shader, then we can get the processed data back with `ComputeBuffer.GetData()`. The `ComputeBuffer` can then be used to apply to new data.

Once, we are done with the `ComputeBuffer` we need to call `ComputeBuffer.Release()` to clean the buffer from the memory.

```c#
// (C# script)
public void UpdateCubes()
{
    ...

    computeShader.Dispatch(0, cubesData.Length / 64, 1, 1);
    
    cubesDataBuffer.GetData(cubesData); // Get the data processed in the compute shader

    // Apply the new data
    for (int i = 0; i < cubes.Count; i++)
    {
        GameObject cube = cubes[i]; // cubes[] is a list that store the cube gameObjects
        CubeData cubeData = cubesData[i];
        cube.transform.position = cubeData.position;
        cube.GetComponent<MeshRenderer>().material.SetColor("_Color", cubeData.color);
    }

    cubesDataBuffer.Release(); // Release the buffer
}
```