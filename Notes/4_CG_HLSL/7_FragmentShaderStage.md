# CG / HLSL Fragment Shader Stage

**Links:**

- ...

## Fragment Shader Stage

Fragment refers to a pixel on the screen, an individual fragment or a group that covers an object area. The Fragment shader stage process every pixels on the computer screen that belong to an object that use the shader.

`frag()` correspond to the Fragment Shader Stage because of the directive `#pragma fragment frag`, without this pragma directive the GPU no longer knows that `frag()` is the Fragment Shader Stage.

```c#
fixed4 frag (v2f i) : SV_Target
```

- The `frag()` function return a four dimensional value (here a `fixed4`) that correspond to the color of a pixel we need to draw.
- `v2f` argument: the argument passed is the `v2f` object returned by the `vert()` function. It allows to use the vertex information we processed in `vert()` inside `frag()`.
- `SV_Target` semantic: unlike `vert()`, `frag()` use a semantic called `SV_Target` (for System Value Target) which correspond to the output value stored in the Render Target. Using this semantic allows `frag()` to update this value stored in the Render Target. 

> ⚠️ here the type returned by `frag()` is a `fixed4` because we use CG code but if we want to use the shader with a scriptable render pipeline we need to replace the `fixed4` type by `half4` or `float4` since fixed value are not compatible with HLSL.

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

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            //Include
            ...

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1);
                float4 vertex : SV_POSITION;
            };

            //Connection variables
            ...

            v2f vert (appdata v)
            {
                v2f o;
                ...
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // By default, we use tex2D() to sample the texture at a specific uv coordinate and find the color we need to use for the pixel. This
                // color value is stored in a fixed4 variable called col for color.
                fixed4 col = tex2D(_MainTex, i.uv);

                // We apply the fog on the color value we sampled on the texture
                UNITY_APPLY_FOG(i.fogCoord, col);

                // Finally, we return the color value we sampled. Thanks to the SV_Target semantic we specified, the returned color value is saved
                // in the Render Target.
                return col;
            }

            ENDCG
        }
    }
}
```

## Rename the Fragment Shader Stage function

When we declare `#pragma fragment frag` we end the declaration by the name of the function that correspond to the fragment shader stage. So in fact we can give the name we want to the function that act as the fragment shader stage.

So if I declare my `#pragma fragment` with a specific name like this:

```c#
#pragma fragment fragmentshaderstage // = #pragma fragment nameOfFunction
```

I can then rename `frag()` to the name I defined in `#pragma fragment ...`

```c#
v2f fragmentshaderstage (appdata v)
{
    ...
}
```