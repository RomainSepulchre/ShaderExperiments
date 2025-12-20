# ColorMask

**Links:**

- https://docs.unity3d.com/6000.2/Documentation/Manual/SL-ColorMask.html

## ColorMask

Allows to limit the GPU to write only one or several of the RGBA channels when rendering an image.

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
        ColorMask RB

        Pass
        {
            ColorMask RB // can be defined in a pass have a specific setting in it
            ...
        }
    }
}
```

### ColorMask modes

- `ColorMask 0` = Disable all channels
- `ColorMask R` = only red channel
- `ColorMask G` = only green channel
- `ColorMask B` = only blue channel
- `ColorMask A` = only alpha channel

### Combining channels

Its also possible to mix several channels by combining them:

- `ColorMask RG` = only red and green channel
- `ColorMask BA` = only blue and alpha channel
- `ColorMask RBA` = only red, blue and alpha channel
