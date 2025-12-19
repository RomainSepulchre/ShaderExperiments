# CGPROGRAM / HLSLPROGRAM

**Links:**

> ⚠️Current up-to-date documentation is on HLSL language but most of the concept remains the same

- https://docs.unity3d.com/6000.3/Documentation/Manual/writing-shader-writing-shader-programs-hlsl.html

## CGPROGRAM...ENDCG / HLSLPROGRAM...ENDHLSL

All sections before CGPROGRAM and after ENDCG (or HLSLPROGRAM / ENDHLSL for an HLSL shader) are written in shaderLab declarative language and all the code inside ...PROGRAM and END... is pure CG/HLSL code that compile the shader.

```c#
Shader "..."
{
    Properties { ... }

    SubShader
    {
        ...
        Pass
        {
            CGPROGRAM // or HLSLPROGRAM for HLSL code

            ...
            // All the CG or HLSL code is written here between ...PROGRAM and END... markers
            ...

            ENDCG // or ENDHLSL for HLSL code
        }
    }
}
```

If CG is still compatible with BIRP, HLSL is now the official shader programming language in Unity. To update the shader to HLSL, we can simply replace CGPROGRAM and ENDCG by HLSLPROGRAM and ENDHLSL. The shader will then compile both in BIRP and SRP. However, if we want to update the program itself to HLSL this need way more work and changes.