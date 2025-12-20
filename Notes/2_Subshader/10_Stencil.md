# Stencil

**Links:**

- https://docs.unity3d.com/6000.3/Documentation/Manual/SL-Stencil.html

## How Stencil buffer works ?

The stencil is way to define if a pixel need to be drawn or not in the fragment shader stage.

The stencil buffer allows to store an int value of eight bits (0 to 255) for each pixel in the frame buffer. Before running the fragment shader, the GPU can run a Stencil Test: it compares the current value in the stencil buffer with a determined reference value to know if the pixel should be drawn or not. If the stencil test passes the GPU performs the following operations such as the Depth Test and if the stencil test fails the GPU skip the rest of the processing for this pixel.

This means that by using the stencil buffer as a mask we can tell the GPU which pixels to draw and which pixels to discard.

The function performed by the stencil test does this:

```c#
if(StencilRef & StencilReadMask [Comp] StencilBufferValue & StencilReadMask)
{
    // Draw pixel 
}
else
{
    // Discard pixel
}
```

## Stencil parameters

### StencilRef

Reference value passed to the stencil buffer. It works as an id that maps all the pixels found in the Stencil Buffer.

This means if we set the StencilRef to 2 on a shader, the value of the Stencil Buffer for all the pixels covering the object area will be 2. 

### StencilReadMask

A mask is automatically created for all the pixels that have a reference value. By default, the value of this mask is 255.

### Comp

Comp is the comparison function we want to use to define if the pixel should be drawn or not.

Here is the list of those functions:

  - `Comp Never` (1): always return false
  - `Comp Less` (2): < 
  - `Comp Equal` (3): ==
  - `Comp LEqual` (4): <=
  - `Comp Greate`r (5): >
  - `Comp NotEqual` (6): !=
  - `Comp GEqual` (7): >=
  - `Comp Always` (8): always return true

> Correspond to an int value in `Rendering.CompareFunction` enum value 

### Pass

Define the operation we want the GPU to perform on the Stencil Buffer when a pixel pases the stencil and depth test.

- **Keep** (0): Keep current content of the stencil buffer
- **Zero** (1): Write 0 into the stencil buffer
- **Replace** (2): Write the refrence value into the buffer
- **IncrSat** (3): Increment the value in the buffer, if the value is already at 255 it stays at 255
- **DecrSat** (4): Decrement the value in the buffer, if the value is already at 0 it stays at 0
- **Invert** (5): Negate all the bits of the current value in the buffer
- **IncrWrap** (6): Increment the value in the buffer, if the value is already at 255 it wraps to 0
- **DecrWrap** (7): Decrement the value in the buffer, if the value is already at 0 it wraps to 255

> Correspond to an int value in `Rendering.StencilOp` enum value

## Use Stencil

```c#
Shader
{
    Properties
    {
        ...
    }
    SubShader
    {
        ...
        Stencil
        {
            // StencilRef (value assigned to the stencil buffer)
            Ref 2 

            // Comp (comparison function used to define if the pixel must be drawn)
            Comp Always 

            // Pass = define the operation we want the GPU to perform on the Stencil Buffer when a pixel pases the stencil and depth test 
            Pass Replace
        }

        Pass
        {
            ...
        }
    }
}
```

## Example with 2 shaders

To use the Stencil Buffer we need at least 2 shaders: one shader for the mask and one for the object that must be masked.

### First shader that define the mask

```c#
Shader ".../Mask"
{
    Properties
    {
        ...
    }
    SubShader
    {
        // Queue is geometry(2000) minus a offset of one so 1999, this means this shader will be processed just before every other geometry objects
        Tags { "Queue"="Geometry-1" }  

        // We also want to disable Z-Write to prevent Unity to process the object based on it's camera-relative position in the scene. 
        Zwrite Off

        // Color Mask is set to 0 to prevent our mask to be rendered in the frame buffer
        ColorMask 0

        // Stencil command to make the object act as a mask
        Stencil
        {
            // StencilRef (value assigned to the stencil buffer)
            // -> We assign a value of 2 to the StencilRef
            Ref 2

            // Comp (comparison function used to define if the pixel must be drawn)
            // -> We use Always to make sure we take into account all the area covered by our objects when we set the stencil Buffer 
            //    to the Stencil Ref Value
            Comp Always
            
            // Pass (Operation the GPU to perform on the Stencil Buffer when a pixel pases the stencil and depth test)
            // -> We tell to replace the current value of the stencil buffer by the StencilRef value
            Pass Replace 
        }

        LOD 100

        Pass
        {
            ...
        }
    }
}
```

### Second shader that define the masked area

```c#
Shader ".../MaskedArea"
{
    Properties
    {
        ...
    }
    SubShader
    {
        Tags { "Queue"="Geometry" }

        // We keep ZWrite active because this object need to be rendered according to its camera-relative position

        // Stencil command so the object can be masked
        Stencil
        {
            // StencilRef (value assigned to the stencil buffer)
            // -> We assign the same value we assigned in the mask shader to the StencilRef (2)
            Ref 2

            // Comp (comparison function used to define if the pixel must be drawn)
            // -> We use NotEqual so that the area of the object that is around the mask will be rendered since the test will pass and the area
            //    that is covered by the mask will not be rendered since the test will fail.
            Comp NotEqual

            // Pass (Operation the GPU to perform on the Stencil Buffer when a pixel pases the stencil and depth test)
            // -> We use keep so the object maintains the current content of the stencil buffer
            Pass Keep
        }

        LOD 100

        Pass
        {
            ...
        }
    }
}
```