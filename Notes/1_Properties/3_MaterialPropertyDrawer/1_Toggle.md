# Toggle Material Property Drawer

**Links:**

- https://docs.unity3d.com/6000.2/Documentation/ScriptReference/MaterialPropertyDrawer.html

## Toggle Property

This material property drawer add a toggle checkbox in the inspector that let you enable and disable some shader features.

```c#
[Toggle] _MyToggleProperty ("My Toggle Property", Float) = 0 // Default value must be 0 or 1 as int
```

Shader doesn't support boolean so instead we use a 0/1 value as a boolean (0=false, 1=true). For this reason the type of the property is a float and its default value must be 0 or 1.

## Use Toggle value to enable/disable shader feature

If we want to be able to enable/disable a shader feature, we need to use `#pragma shader_feature` inside CGPROGRAM to generate different shader variant according to the state of our toggle property.

`#pragma shader_feature` is a pragma directive where we declare a keyword that we can use later in the code to branch between different version of the shader code.

When using `#pragma shader_feature` with a Toggle material property drawer, the keyword we declare must be the name of our toogle property in capital letter followed by **_ON** which means the condition is fullfiled when the toggle is enabled in the inspector.

```c#
// Toggle property
[Toggle] _MyToggleProperty ("My Toggle Property", Float) = 0 // Default value must be 0 or 1 as int
```

```c#
// #pragma shader_feature that use our toggle property
#pragma shader_feature _MYTOGGLEPROPERTY_ON // keyword is our property name in capital followed by _ON
```
>❔The keyword must be in capital letter because it is a constant.

### Use keyword to branch between 

Once our keyword is defined we can use it with `#if` in the CG/HLSL code to branch between different behaviour.

```c#
#if _MYTOGGLEPROPERTY_ON
    // Do something
#else
    // Do something else
#endif
```

>⚠️`#pragma shader_feature` cannot compile multiple variants of a shader for an application this means it's not possible to change the value of the toogle in a build at execution time. To do that we need to use `#pragma multi_compile`.

### Example: Enable/Disable a texture

```c#
Shader "..."
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        // Toggle property to enable/disable the texture
        [Toggle] _EnableTexture ("Enable Texture", Float) = 0 // Default value must be 0 or 1 as int
    }

    SubShader
    {
        ...
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog // make fog work

            // #pragma shader_feature to define the keyword for our toggle property
            #pragma shader_feature _ENABLETEXTURE_ON

            // Include, appdata and v2f structs
            ...

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            v2f vert (appdata v)
            {
                ... 
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                // Use the keyword to enable/disable the sampleing of the texture
            #if _ENABLETEXTURE_ON
                fixed4 col = tex2D(_MainTex, i.uv);
            #else
                fixed4 col = fixed4(1,1,1,1);
            #endif

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
```

## ToggleOff

If we need to invert the toggle condition and do something when the toggle is disabled we can use `[ToogleOff]` instead of `[Toggle]`.

```c#
[ToggleOff] _MyToggleProperty ("My Toggle Property", Float) = 0 // Default value must be 0 or 1 as int
```

When using`[ToogleOff]` the suffix we add when declaring the keyword must be **_OFF** instead of **_ON**.

```c#
// #pragma shader_feature that use our toggle property
#pragma shader_feature _MYTOGGLEPROPERTY_OFF // keyword is our property name in capital followed by _OFF
```

## Use a custom property keyword

If we want to use a custom keyword rather than using the default one (property name in capital followed by _ON), we can specify the keyword when declaring our toggle property.

```c#
[Toggle(MY_CUSTOM_KEYWORD)] _MyToggleProperty ("My Toggle Property", Float) = 0 // Default value must be 0 or 1 as int
```

Since we defined a custom keyword, we no longer need to add the suffix **_ON** or **_OFF** when declaring the keyword with `#pragma shader_feature`.

```c#
// #pragma shader_feature that use our toggle property
#pragma shader_feature MY_CUSTOM_KEYWORD // keyword is defined at toggle property declaration
```

## Pragma multi_compile

`#pragma shader_feature` comes with a limitation, it only compile one version of the shader when we build the project. This means we can't change the value of the property at execution time in a build. If we want to be able to do that we need to compile every shader variant, the pragma directive that allows to do this is `#pragma multi_compile`.

To use it with the toggle property we need to do 2 things:
- replace `#pragma shader_feature` by `#pragma multi_compile`
- add two underscore  **__** before we declare the keyword to tell we want to compile the on and off version of the keyword.

Adding **__** before the keyword in a `#pragma multi_compile` directive tell the compiler that the keyword has an on and off state and that we want to compile both variant.

```c#
// #pragma multi_compile that use our toggle property
#pragma multi_compile __ _MYTOGGLEPROPERTY_ON
```