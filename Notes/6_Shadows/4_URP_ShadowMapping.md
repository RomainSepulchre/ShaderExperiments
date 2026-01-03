# URP Shadow mapping

**Links:**

- https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@14.0/manual/use-built-in-shader-methods-shadows.html

## Convert our unlit shader to URP

If we start from an unlit BIRP shader, the first things we need to do is to make our shader compatible with universal render pipeline.

1. Set the `RenderPipeline` tag

To tell unity the shader use the universal render pipeline we need to add a `RenderPipeline` tag and set it to `UniversalRenderPipeline`.

```c#
SubShader
{
    Tags
    {
        "RenderType"="Opaque"
        "RenderPipeline"="UniversalRenderPipeline" // Add URP tag
    }

    ...
}
```

2. Switch to HLSL

The new SRP are only compatible with HLSL so we need to convert our CG code to HLSL to make the shader compatible with URP.

In our color pass we can replace `CGPROGRAM` and `ENDCG` by `HLSLPROGRAM` and `ENDHLSL`.

```c#
Pass
{
    // URP is only compatible with HLSL so we switch to HLSLPROGRAM
    HLSLPROGRAM
    
    ...

    ENDHLSL
}
```

We also don't need *UnitCG.cginc* anymore instead we include *Core.hlsl* and we can also include *HLSLSupport.cginc* to keep a compatibility with some of CG features like the `fixed` type.

```c#
// Include HLSLSupport.cginc to improve CG type compatibility with HLSL (ex: fixed) 
#include "HLSLSupport.cginc"
    
// Include core HLSL functionalities (HLSL equivalent of UnityCG.cginc)
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
```

Finally, we need to replace `UnityObjectToClipPos()` that was part of *UnitCG.cginc* by its HLSL equivalent which is part of *Core.hlsl*: `TransformObjectToHClip()`.

```C#
v2f vert (appdata v)
{
    v2f o;
    o.vertex = TransformObjectToHClip(v.vertex); // HLSL equivalent of UnityObjectToClipPos()
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    
    return o;
}
```

## URP Shadow caster pass

Like in the built-in render pipeline, we need to create a new pass if we want the object to be a shadow caster.

However, instead of writing a complete shadow caster pass in our shader we can get it from other URP shader that already implement a shadow caster pass like the Lit shader.

To do that we use the `UsePass` command. This command allows us to specify the path of a pass inside a shader to use this pass in another shader without having to write it completely again. To get the shadow caster pass of URP Lit shader we need to use the path: `"Universal Render Pipeline/Lit/ShadowCaster"`.

```c#
// Use shadow caster pass from URP Lit shader
UsePass "Universal Render Pipeline/Lit/ShadowCaster"
```

If we want to see the code inside the pass we can still open the Lit shader and look for the shadow caster pass.

## URP Shadow map

For our shadow map everything still happens inside the default color pass.

### Pass configuration

Like with our BIRP shadow map we need to declare a `LightMode` tag to tell Unity the object is affected by light, however since we now are in URP we need to set the tag to `UniversalForward` to tell unity we use the URP forward renderer.

```c#
  Tags { "LightMode"="UniversalForward"} // Set LightMode tag to Universal to tell unity this is an URP forward rendering pass
```

To have access to all the lighting functionnalities we also need to add a new pragma directive and to include another .hlsl file.

The pragma directive we add is `#pragma multi_compile _ _MAIN_LIGHT_SHADOW`, it is necessary if we want the shader to be able to get the main light shadow map

```c#
// Pragma directive to allow the shader to access the main light shadow map
#pragma multi_compile _ _MAIN_LIGHT_SHADOW
```

The other file we need to include is *Lighting.hlsl*, it contains all the HLSL functionnalities we need to work with lights.

```c#
// Include HLSL Lighting functionalities
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
```

### Output and vertex shader

If we already have the `vertex` and the `uv` in our inputs we only need to add one output that will store the shadow coordinates. We bind it to the `TEXCOORD1` semantic.

```C#
 struct v2f
{
    float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
    float4 shadowCoord : TEXCOORD1; // Add a variable to store shadow coordiantes
};
```

Now, like we would have done in BIRP, we need to process the vertex position inside the vertex shader to get the shadow coordinates. However, in URP we do it differently.

In URP we use a type called `VertexPositionInputs`, this type defined inside *Core.hlsl* store the position of a vertex in most of the coordinate space (world, view, clip, ndc).

```c#
// VertexPositionInputs type declaration from Core.hlsl
struct VertexPositionInputs
{
    float3 positionWS; // World space position
    float3 positionVS; // View space position
    float4 positionCS; // Homogeneous clip space position
    float4 positionNDC;// Homogeneous normalized device coordinates
};
```

To fill `VertexPositionInputs` we use the function `GetVertexPositionInputs()`. It takes a position in object-space, convert it in all the different coordinate space and return the result in a `VertexPositionInputs` variable.

```c#
// GetVertexPositionInputs function declaration from ShaderVariablesFunctions.hlsl
VertexPositionInputs GetVertexPositionInputs(float3 positionOS)
{
    VertexPositionInputs input;
    input.positionWS = TransformObjectToWorld(positionOS);
    input.positionVS = TransformWorldToView(input.positionWS);
    input.positionCS = TransformWorldToHClip(input.positionWS);

    float4 ndc = input.positionCS * 0.5f;
    input.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
    input.positionNDC.zw = input.positionCS.zw;

    return input;
}
```

Finally, we use `GetShadowCoord()` on the returned `VertexPositionInputs` to get our shadow coordinate and pass them to the fragment shader.

```c#
v2f vert (appdata v)
{
    v2f o;
    o.vertex = TransformObjectToHClip(v.vertex); // HLSL equivalent of UnityObjectToClipPos()
    o.uv = TRANSFORM_TEX(v.uv, _MainTex); 

    // Convert object-space pos to the other spaces (world, view, clip, ndc)
    VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
    // Use GetShadowCoord() on vertexInput to get shadow coordinate
    o.shadowCoord = GetShadowCoord(vertexInput);
    return o;
}
```

### Apply shadow in the fragment shader

In URP to get our shadow data we use `GetMainLight()` to retrieve all the light data from the main light (light direction, attenuation, light color, etc).

If we pass our `float4` shadow coordinate to `GetMainLight(float4 shadowCoord)`, the function will automatically calculate the shadow based on the coordinate.

```c#
// GetMainLight function declarations from ShaderVariablesFunctions.hlsl

Light GetMainLight()
{
    Light light;
    light.direction = _MainLightPosition;
    light.distanceAttenuation = unity_LightData.z;
    light.shadowAttenuation = 1.0;
    light.color = _MainLightColor.rgb;
    return light;
}

// Get light and provide shadow coord to calculate the shadow attenuation
Light GetMainLight(float4 shadowCoord) 
{
    Light light = GetMainLight();
    light.shadowAttenuation = MainLightRealtimeShadow(shadowCoord);
    return light;
}

// The function also has a third variation where we can include the shadowMask
```

Once we get the main light data we simply have to use its `shadowAttenuation` variable to apply it on the color.

```c#
fixed4 frag (v2f i) : SV_Target
{
    // Get Main light data
    Light light = GetMainLight(i.shadowCoord);
    
    // Get shadow from main light data
    float3 shadow = light.shadowAttenuation;
    
    // Sample color texture
    fixed4 col = tex2D(_MainTex, i.uv);
    
    // Apply shadow to the color
    col.rgb *= shadow;

    return col;
}
```


