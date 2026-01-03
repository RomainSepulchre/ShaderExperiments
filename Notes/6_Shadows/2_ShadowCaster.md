# Shadow caster

**Links:**

- https://docs.unity3d.com/6000.3/Documentation/Manual/built-in-shader-examples-shadow-casting.html

## Implement a shadow caster pass

Like we said previously in shadow mapping, the shadow caster is the shadow area projected by an object. If we want to implement it in a shader we need a add new pass on top of our default color pass and we need to configure the pass.

### Configure pass name and tags

The first thing we can is to give a name to the pass. The name of a pass is used for organization and to differentiate passes but it has no impact on shader rendering. The [`UsePass`](https://docs.unity3d.com/2021.3/Documentation/Manual/SL-UsePass.html) command also use the name of a pass to call a pass from another shader and reduce code duplication.

The second thing we need to configure is the tags of the pass. If we want unity to know this is a shadow caster pass we need to add the tag `"LightMode"="ShadowCaster"`.

We also add `Zwrite On` to be sure we write in the Z-Buffer.

```c#
Shader ""
{
    ...

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        // Shadow caster pass: will handle shadow projection
        Pass
        {
            Name "Shadow Caster"
            
            Tags
            {
                "LightMode"="ShadowCaster" // Add the LightMode tag and set it to "ShadowCaster" so unity will recognize the pass as a shadow casting pass
            }
            
            ZWrite On

            ...
        }

        // Default color pass: will handle shadow map
        Pass
        {
            ...
        }
    }
}
```

### Simple shadow caster pass (not compatible with lighting settings)

If we want to make a simple version of a shadow pass that will only project shadows and won't interact with the lighting shadow settings we don't need to add a lot in our pass.

The only input and ouput we need is the vertex position, we pass it the fragment shader the in clip-space like usual.

```c#
Pass
{
    ...

    struct appdata
    {
        float4 vertex : POSITION; // Since it is shadow caster pass we only need the vertices position as input and output
    };

    struct v2f
    {
        float4 vertex : SV_POSITION; // Pass vertex position to frag()
    };

    v2f vert (appdata v)
    {
        o.vertex = UnityObjectToClipPos(v.vertex);        
        return o;
    }

    ...
}
```

Since the shadow caster correspond to a shadow projection, the only thing we need to do in the fragment shader is to return **0** which correspond to the black color.

```c#
Pass
{
    ...

    fixed4 frag (v2f i) : SV_Target
    {
        return 0;
    }
    ENDCG
}
```

If we want to make this simple pass compatible with the lighting shadow settings we need to define more property. A more effective way is use the macro provided by UnityCG.cginc to implement our shadow caster pass.

## Macro shadow caster pass

Using macro allows us to make a shadow caster pass fully compatible with the lighting settings in only a few lines. For that we will only use 3 macros: `V2F_SHADOW_CASTER`, `TRANSFER_SHADOW_CASTER_NORMALOFFSET` and `SHADOW_CASTER_FRAGMENT`.

First, we need to add a little pragma directive (`#pragma multi_compile_shadowcaster`) to allow the shader to compile all the shadow variants enabled by the macro. We also need to ensure we include UnityCG.cginc since all the macro we will use are part of it.


```c#
#pragma multi_compile_shadowcaster

#include "UnityCG.cginc"
```

For our inputs we need the vertex position and the normal.

```c#
struct appdata
{
    float4 vertex : POSITION; // Get vertex position
    float3 normal : NORMAL; // When using macro we also need to add the normal in the input if we want TRANSFER_SHADOW_CASTER_NORMALOFFSET(o) to work

};
```

The only output we need is `V2F_SHADOW_CASTER` macro. In fact this macro automatically declare 4 outputs:
- `vertex : SV_POSITION`
- `normal_world : TEXCOORD1`
- `tangent_world : TEXCOORD2`
- `binormal_world : TEXCOORD3`

```c#
struct v2f
{
    V2F_SHADOW_CASTER;
};
```

Inside the vertex shader instead of manually processing the data from the input to the output, we simply call `TRANSFER_SHADOW_CASTER_NORMALOFFSET()` macro. It will automatically process our inputs and pass them inside the outputs.

```C#
v2f vert (appdata v)
{
    v2f o;

    // Transform the vertex and normal input and pass them to v2f
    TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)

    return o;
}
```

>⚠️ the missing ";" after `TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)` is normal, some macro statement don't have to be closed with a semicolon.

Finally, inside the fragment shader we only call `SHADOW_CASTER_FRAGMENT()` that will handle the color output for the shadow projection.

```c#
fixed4 frag (v2f i) : SV_Target
{
    // Handle color output for shadow projection
    SHADOW_CASTER_FRAGMENT(i)
}
```
This macro statement also doesn't need to be closed with a ";".