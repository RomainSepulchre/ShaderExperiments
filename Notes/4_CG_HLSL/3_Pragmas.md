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

## Pragma shader_feature

`#pragma shader_feature` is a pragma directive thats allows us to generate different shader variant by declaring keyword that we use in the CG/HLSL code to branch between different version of the shader.

The keyword we declare is usually linked to property and we modify the shader depending on the state of this property. A good example of this is the [toggle property](../1_Properties/3_MaterialPropertyDrawer/1_Toggle.md#use-toggle-value-to-enabledisable-shader-feature).

```c#
// Declaring a keyword with the pragma 
#pragma shader_feature MYKEYWORD
```

```c#
// Use the keyword to branch between behaviour
#if MYKEYWORD
    ...
#else
    ...
#endif
```

>⚠️`#pragma shader_feature` cannot compile multiple variants of a shader for an application this means it's not possible to change the value of the toogle in a build at execution time. To do that we need to use `#pragma multi_compile`.

## Pragma multi_compile

`#pragma shader_feature` comes with a limitation, it only compile one version of the shader when we build the project. This means we can't change the value of the property at execution time in a build. If we want to be able to do that we need to compile every shader variant, the pragma directive that allows to do this is `#pragma multi_compile`.

```c#
// #pragma multi_compile that use our toggle property
#pragma multi_compile __ _MYTOGGLEPROPERTY_ON
```