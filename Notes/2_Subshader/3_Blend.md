# Blend

**Links:**

- https://docs.unity3d.com/6000.3/Documentation/Manual/SL-Blend.html

## Blend command

Blending is the process of mixing 2 pixels into one. It happens at the end of the render pipeline at a stage called Merging where the color of the pixel is merged with the frame buffer. Merging is also where the Stencil-Buffer, Z-Buffer and Color blending are executed.

The 2 pixels merged are also called the source and the destination. The source is the pixel RGB Color the fragment shader output and the destination is RGB Color written in the destination frame buffer (also known as RenderTarget).

When blending is enabled the source and destination colors are mixed to get a new color that override the values from the destination and when blending options are not enabled the values from the source simply override the values from the destination.

`Blend` is an optionnal command that is mainly used to work with transparent objects. The effect of the parameter is similar to the blending modes in Photoshop.

The syntax to declare a `Blend` is: `Blend SourceFactor DestinationFactor`.

> The `SourceFactor` and `DestinationFactor` are 3D vectors that are applied to the source and destination to achieve interesting effect.

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
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha // can be defined in a pass have a specific setting in it
            ...
        }
    }
}
```

> Like the tags, Blend can be declared in the Subshader or in the Pass.

### Blend Factors

- **Off** = disable blending options
- **One** = (1,1,1)
- **Zero** = (0,0,0)
- **SrcColor** = RGB value of the source
- **SrcAlpha** = Alpha value of the source
- **OneMinusSrcColor** = 1 - RGB value of the source (1 - R, 1 - G, 1 - B)
- **OneMinusSrcAlpha** = 1 - Alpha value of the source (1 - A, 1 - A, 1 - A)
- **DstColor** = RGB value of the destination
- **DstAlpha** = Alpha value of the destination
- **OneMinusDstColor** = 1 - RGB value of the destination (1 - R, 1 - G, 1 - B)
- **OneMinusDstAlpha** = 1 - Alpha value of the destination (1 - A, 1 - A, 1 - A)

### Common blending types

- **Blend SrcAlpha OneMinusSrcAlpha** = Common transparent blending
- **Blend One One**= Additive blending color
- **Blend OneMinusDstColor One** = Mild additive blending color
- **Blend DstColor Zero** = Multiplicative blending color
- **Blend DstColor SrcColor** = Multiplicative blending x2
- **Blend SrcColor One** = Blending overlay
- **Blend OneMinusSrcColor One** = Soft light blending
- **Blend Zero OneMinusSrcColor** = Negative color blending

## Note

> Alpha channel blending is done the same way as the RGB blending but in an independant process since it's not frequently used. This also allows to optimize the writing in the Render Target.