# Tags

**Links:**

- https://docs.unity3d.com/6000.2/Documentation/Manual/SL-SubShaderTags.html

## What is a Tag ?

Tags are labels that specify to the renderer how and when the shader must be processed. They can be used to know how a shader will be rendered or how a group of shaders will behave graphically.

The syntax for adding a tag is: `"TagName"="TagValue"`.

Tags can be declared either within a Subshader or inside a Pass section. Tags written in Subshader will affect every Pass included in it while Tags written in a Pass only affect this specific Pass.

```c#
Shader
{
    Properties
    {
        ...
    }
    SubShader
    {
        Tags { "TagName"="TagValue" }
        LOD 100

        Pass
        {
            Tags { "TagName"="TagValue" }
            ...
        }
    }
}
```

## Queue Tag

The function of the Queue Tag is to is to define the order in which the object must be processed by the GPU. By default this tag isn't show as a line of code because it is automatically compiled in the GPU.

```c#
Tags { "Queue"="Geometry" }
```

Queue has a number value ranging from 0 to 5000, 0 is the farthest element from the camera and 5000 the closest. These values are organized in predifined groups:

- **Background** (*0-1499, default value=1000*): used for elements very far from camera such as a skybox.
- **Geometry** (*1500-2399, default value=2000*): used for opaque objects in the scene (default value in the Queue).
- **AlphaTest** (*2400-2699, default value=2450*): used for semi-transparent objects that are in front of an opaque object but behind a transparent object.
- **Transparent** (*2700-3599, default value=3000*): used for tranparent elements that must be in front of the others.
- **Overlay** (*3600-5000, default value=4000*): used for element rendered in front of the scene like UI ir images.

> HDRP use the Render Queue differently by using two control methods: Material order and Renderer order.

### Offset Queue

It's also possible define an offset from a queue by specifying it after the queue name (`"Queue"="QueueName+/-Offset"`). For example this is useful for transparent water, we want to draw after opaque objects but before transparent objects (`"Queue"="Transparent-1"`).

## Render type Tag
        
This tag define the type of render the object will use. 

```c#
Tags { "RenderType"="Opaque" }
```

RenderType values are:

- Opaque (default)
- Transparent
- TransparentCutout
- Background
- Overlay
- TreeOpaque
- TreeTransparentCutout
- TreeBillboard
- Grass
- GrassBillboard

One way of using the RenderType tag is to overwrite the behavior of a shader and add an effect on any material that matches a determined type. To do that we need at least 2 shaders a replacement one (color of effect to add at runtime) and a shader to be replaced (shader assigned on a material). This can be used to create some visual effect like an edge detection by example.

> See demo in Examples/Tags/RenderType and https://docs.unity3d.com/6000.2/Documentation/Manual/SL-ShaderReplacement.html