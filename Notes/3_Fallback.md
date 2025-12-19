# Fallback

**Links:**

- https://docs.unity3d.com/6000.3/Documentation/Manual/SL-Fallback.html

## Why and how use the Fallback block

Fallback block helps to avoid GPU compilation error on the shader by providing another the path to another fallback shader to use when the principal shader failed to compile.

>On a multiplatform game it is recommended to specify a fallback shader to ensure it works on most devices. Also when specifying a fallback shader it is usually recommended to use a shader that is included in the software to ensure the program continues to run correctly (Mobile/Diffuse, Mobile/Unlit for example or the standard BIRP/URP shader).

To specify the fallback shader we just need to write Fallback followed by the path of the shader to use as fallback. In the example below we use Mobile/Unlit shader as a fallback shader. So if any error happens when compiling the main shader, Mobile/Unlit shader will be used instead.

```c#
Shader "..."
{
    Properties
    {
        ...
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            ...
        }
    }

    // We set "Mobile/Unlit" as the fallback shader
    Fallback "Mobile/Unlit"

}
```

> Note: Not specifying the Fallback command or specifying Fallback Off allows to omit the command