# Run a Compute Shader

**Links:**

- https://docs.unity3d.com/6000.3/Documentation/Manual/class-ComputeShader.html
- https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/sm5-attributes-numthreads

## How to run a Compute shader ?

Just like a vertex-fragment shader use shaderlab to communicate between Unity and `CGPROGRAM/HLSLPROGRAM`, a compute shader require to be associated with a c# script to declare global variables and buffers that we will connect with the CG/HLSL code.

In this c# script we create a render texture that we assign to our compute shader with `computeShader.SetTexture()` as the `Result` texture and once we are ready to run the compute shader we call `computeShader.Dispatch()` that will execute our compute shader function.

Here the example of a simple c# script that control a compute shader:

```C#
public class ComputeShaderController : MonoBehaviour
{
    
    public ComputeShader shader; // public variable to access the compute shader from the c# script
    
    public RenderTexture rt; // RenderTexture to store the texture calculated by the compute shader 
    
    private int texSize = 256; // size of our texture (usually a power of 2: 128, 256, 512, 1024, ...)
    
    Renderer rend; // Renderer component to apply our compute shader texture to a material

    void Start()
    {
        // Initialize our render texture with its size, depthBuffer and texture format
        rt = new RenderTexture(texSize, texSize, 0, RenderTextureFormat.ARGB32);
        
        // Enable random writing on the RenderTexture
        rt.enableRandomWrite = true;
        
        // Create texture: RenderTexture builder does not actually create a texture, it's only created when Create() is called
        rt.Create();
        
        // Get Renderer and enable it
        rend = GetComponent<Renderer>();
        rend.enabled = true;
        
        // Assign our RenderTexture to the Result global variable of our Compute shader
        shader.SetTexture(0, "Result", rt);
        
        // Apply RenderTexture to our object material
        rend.material.SetTexture("_MainTex", rt);
        
        // Dispatch: Configure thread groups and execute the compute shader
        shader.Dispatch(0, texSize/8, texSize/8, 1);        
    }
}
```

## Create the RenderTexture

In our compute shader we declare a `RWTexture2D<float4>` texture but it's just an empty shell and we need to have an actual `RenderTexture` where the value of every texel will be stored. This `RenderTexture` must be created from a c# script before it can be assigned to the compute shader.

To do that we initialize a new `RenderTexture` variable with 4 arguments:
- **width** of the texture
- **height** of the texture
- **depth buffer** of the texture
- **format** of the texture. 

```c#
public class ComputeShaderController : MonoBehaviour
{
    ...
    
    public RenderTexture rt; // RenderTexture to store the texture calculated by the compute shader
    private int texSize = 256; // size of our texture (usually a power of 2: 128, 256, 512, 1024, ...)
    
    ...

    void Start()
    {
        // Initialize our render texture with its width, height, depthBuffer and texture format
        rt = new RenderTexture(texSize, texSize, 0, RenderTextureFormat.ARGB32);

        ...     
    }
}
```

Then, we need to ensure `enableRandomWrite` is enabled on our `RenderTexture`. We need to do that because thread groups are not synchronized, so we can't determine which texel will be calculated first.

```c#
// Enable random writing on the RenderTexture
rt.enableRandomWrite = true;
```

Finally, we can create the texture. `RenderTexture` builder doesn't create an actual texture, the texture is only created when we call `RenderTexture.Create()`.

```c#
// Create the actual texture
rt.Create();
```

## Assign the RenderTexture to the compute shader

We have a texture but it's still an empty texture, if we want to store the result of our compute shader in it we must assign the `RenderTexture` to our compute shader `RWTexture2D<float4> Result` variable.

To do that we call `ComputeShader.SetTexture()`. This function require 3 arguments:

- *kernelIndex*: the index of the function that will process our texture. Like explained [here](./1_ComputeShader#pragma-kernel-directive) every function declared with `#pragma kernel` has an ID defined by its order in the code. In this case it's *0* because we only have one function.
- *name*: the name of the buffer variable from the compute shader that will be assigned with the `RenderTexture`, in this case its *"Result"* our `RWTexture2D<float4>` variable.
- *texture*: the `RenderTexture` that will be assigned to the buffer variable.

```c#
shader.SetTexture(0, "Result", rt);
```

## Dispatch and thread groups configuration

When we are ready to run our compute shader we call `ComputeShader.Dispatch()`.

`Dispatch()` is a function that generate the thread groups and use them to process the compute shader function. The function takes 4 arguments:
- *kernelIndex*: the index of the function we want to process. Like explained [here](./1_ComputeShader#pragma-kernel-directive) every function declared with `#pragma kernel` has an ID defined by its order in the code.
- *threadGroupX*: number of thread groups in X dimension
- *threadGroupY*: number of thread groups in Y dimension
- *threadGroupZ*: number of thread groups in Z dimension

```c#
// Dispatch: Configure thread groups and execute the compute shader
shader.Dispatch(0, texSize/8, texSize/8, 1);    
```

### Configure the number of thread groups

Every thread group has the number of threads we define with `numthreads`. This means that if we keep the default `numthreads` value (`[numthreads(8,8,1)]`), every thread group will have 64 threads that will calculate a box of 8 by 8 by 1 texels (every thread calculate the value of a texel inside the box).

To configure the number of thread groups correctly we need to know how many of these thread groups we need in every axis to fill the entirety of our texture. With the **size of texture** and the **XYZ value of `numthreads`**, its easy to calculate.

If we consider that we must have:

- **Width of the texture** = **number of thread group in X axis** * **numthreads X value**
- **Height of the texture** = **number of thread group in Y axis** * **numthreads Y value**
- **Depth of the texture** = **number of thread group in Z axis** * **numthreads Z value**

Then we can do:

- **number of thread group in X axis** = **Width of the texture** / **numthreads X value**
- **number of thread group in Y axis** = **Height of the texture** / **numthreads Y value**
- **number of thread group in Z axis** = **Depth of the texture** / **numthreads Z value**

> In our example the texture size is **256*256** and we use `[numthreads(8,8,1)]` so we have:  
> - *threadGroupX* = 256 / 8 = 32
> - *threadGroupY* = 256 / 8 = 32
> - *threadGroupZ* = 1 / 1 = 1
>  
> Our texture will be calculated by **a grid of 32 * 32 * 1 thread groups** each **composed of 8 * 8 * 1 threads** and **every thread process the value of a specific texel** which gives us a resolution of 256 * 256 * 1.

>❔ A way to see that really well is to use the same number of group threads (32 * 32 * 1) but change the `numthreads` to 4 * 4 * 1. The texture will only cover a quarter of our 256\*256 `RenderTexture` because we only calculate 128\*128 texels (32\*4 by 32\*4 by 1\*1). 