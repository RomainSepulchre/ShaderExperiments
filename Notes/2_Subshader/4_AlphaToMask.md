# AlphaToMask

**Links:**

- https://docs.unity3d.com/6000.2/Documentation/Manual/SL-AlphaToMask.html

## AlphaToMask

AlphaToMask is a cheaper way to add a transparency effect. AlphaToMask applies a covering mask over the alpha channel that discard pixels depending on the alpha value. However, contrary to blending where the alpha values range from 0.0 to 1.0, with AlphaToMask the coverage mask can only assign values of 1 or 0 to the alpha channel. This means the transparency effect will be harsher. This is very useful for vegetation for example.

Another advantage of AlphaToMask is that contrary to blending you don't need to add the transparency tags (Queue and RenderType).

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
        Tags { "RenderType"="Opaque" } // Transparency even with Opaque rendering
        AlphaToMask On

        Pass
        {
            AlphaToMask On // can be defined in a pass have a specific setting in it
            ...
        }
    }
}
```

> Like Tags, AlphaToMask can be declared inside the subshader or inside a specific Pass.

### AlphaToMask Modes
- **On** = Use the alpha as a mask to render only white pixels of the alpha channel.
- **Off** (default value) = AlphaToMask is disabled