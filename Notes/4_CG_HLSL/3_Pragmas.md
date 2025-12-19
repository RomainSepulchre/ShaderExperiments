# CG / HLSL Pragmas

**Links:**

- https://docs.unity3d.com/6000.4/Documentation/Manual/SL-PragmaDirectives.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/writing-shader-programs-pragma-directives.html

## Pragma

`#pragma` is a preprocessor directive that provide machine or OS specific features while maintaining compatibility with C/C++ language. It helps the program to recognize and compile some certain function. In CG/HLSL some pragma directives are needed to make sure the GPU correctly recognize the nature of certain functions.

For example `#pragma vertex vert` and `#pragma fragment frag` are needed to make sure the GPU compile the `vert()` and `frag()` functions as the vertex shader stage and fragment shader stage.

Here is a more detailed explanation of the default pragmas:

```c#
Shader "..."
{
    Properties { ... }

    SubShader
    {
        ...
        Pass
        {
            CGPROGRAM

            // #pragma vertex vert: Allows the GPU to recognize and compile the vert() function as the vertex shader stage
            #pragma vertex vert

            // #pragma vertex vert: Allows the GPU to recognize and compile the vert() function as the vertex shader stage
            #pragma vertex vert

            // #pragma multi_compile_fog: this directive has 2 parts. "multi_compile" refers to a shader variant that generate variants
            // depending on functionnalities within the shader. "_fog" enable the fog functionnality from the lighting window on the object that
            // fade the object like it was disapearing in the fog when it is too far.
            #pragma multi_compile_fog

            // Include
            ...

            // appdata and v2f structs
            ...

            // Connection variables
            ...

            // vert() is recognized and compiled as the vertex shader stage because of "#pragma vertex vert" directive
            v2f vert (appdata v)
            {
                ...
            }

            // frag() is recognized and compiled as the fragment shader stage because of "#pragma fragment frag" directive
            fixed4 frag (v2f i) : SV_Target
            {
                ...
            }

            ENDCG
        }
    }
}
```
