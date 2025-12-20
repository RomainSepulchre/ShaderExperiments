# SubShader Block

**Links:**

- https://docs.unity3d.com/6000.2/Documentation/Manual/SL-SubShader-object.html

## SubShader Block

Each shader is composed of a least one subShader section where we declare the shader command, the pass(es) and the actual shader code. When there is several subshader, Unity process all of them from the first to the last and choose the more suitable subshader for the current hardware characteritics. If no subshader are supported Unity will try to use the Fallback component if it exist 

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
            CGPROGRAM
            ...
            ENDCG
        }
    }
}
```