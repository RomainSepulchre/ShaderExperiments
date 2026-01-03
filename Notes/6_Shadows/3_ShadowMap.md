# Shadow map

**Links:**

- https://discussions.unity.com/t/what-does-the-function-computescreenpos-in-unitycg-cginc-do/565450/10
- https://europe1.discourse-cdn.com/unity/optimized/3X/1/0/10b90837995f81ec931dfe37f14f872b4e6b1c68_2_500x500.jpeg

## Implement a shadow map in color the color pass

Like we said previously in shadow mapping, the shadow map is the shadow area cast on the object. If we want to implement it in a shader we need to modify the default color pass.

### Configure pass name and tags

The first thing we can do is to give a name to the pass. The name of a pass is used for organization and to differentiate passes but it has no impact on shader rendering. The [`UsePass`](https://docs.unity3d.com/2021.3/Documentation/Manual/SL-UsePass.html) command also use the name of a pass to call a pass from another shader and reduce code duplication.

The second thing we need to configure is the tags of the pass. If we want unity to know this pass is affected by lighting we need to add the tag `"LightMode"="ForwardBase"`.


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
            ...
        }

        // Default color pass: will handle shadow map
        Pass
        {
            Name "Color And Shadow Map"
            Tags
            {
                "LightMode"="ForwardBase" // Set the LightMode to ForwardBase to let Unity know this pass is affected by lighting
            }

            ...
        }
    }
}
```

### Input, Ouputs and Shadow map texture

The inputs are classic inputs we don't need to add any specific inputs if we already have the vertex position and the uv coordinates.

In the ouputs we need to add a `float4` that will store the shadow coordinates, since we need to store a `float4` value we use a `TEXCOORD[n]` semantic.


If we want to be able to access the generated shadow map we also need to declare a uniform `sampler2D` variable named `_ShadowMapTexture`. This name refers to a global texture that store the calculated shadow map and we don't have to declare a corresponding property.

```c#
...

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    UNITY_FOG_COORDS(1)
    float4 vertex : SV_POSITION;
    
    float4 shadowCoord : TEXCOORD1; // Declare coordinates for the shadow map
};

sampler2D _MainTex;
float4 _MainTex_ST;

// Global texture variable that store the shadow map
sampler2D _ShadowMapTexture;

...
```

### Vertex position to Shadow map UV coordinate

If we want to be able to sample our shadow map at the right position we need to transform our vertex position to a UV coordinate.

When we call `UnityObjectToClipPos()` we convert a position from object-space to clip-space but what we actually do is that we convert the coordinates from object-space to world-space, then from world-space to view-space and finally from view-space to clip-space.

`UNITY_MATRIX_P` is the matrix we use for this last conversion from view-space to clip-space, it defines the object vertex position in relation to camera fustrum.

One of the very interesting features of clip-space coordinates is that we can generate **Normalized Device Coordinate** (or **NDC**) from them. **NDC** are coordinates that range between -1 and 1 and map to a position on the screen.

<img src="https://lh5.googleusercontent.com/proxy/HYNR22dRJvwcyZevRAm6a8yDgtk3lzKippNJnpl5XOolT0Phji_9s5lMsnAekfKKPelB_Ss28Hj2YGxRY3HuosO6nWjYObqbFOYmUMZTCsu6QmBe_Xno6Oz4" alt="Normalized Device Coordinates" width="400"/>

To generate **Normalized Device Coordinate** we just have to divide the X, Y and Z component of a clip-space coordinate by its W component.

```c#
xNDC = clipPos.x / clipPos.w;
yNDC = clipPos.y / clipPos.w;
zNDC = clipPos.z / clipPos.w
```

>❔ In a clip-space position, W is the maximum value or to say it differently the range of a clip space position is [-w,w]. This why when we divide the X, Y or Z by W we get a value within a range of [-1,1].

Now that we have a **NDC**, we have a coordinate that map to a position on the screen, however it ranges from -1 to 1 and UV coordinates ranges from 0 to 1 so we need to remap the range of the coordinate from [-1,1] to [0,1].

The calculation is simple, it is the opposite of what we do with normal maps to convert RGB value to XYZ coordinates:

$UVcoord = (NDCcoord + 1) / 2$

### Process shadow map coordinate

Now that we have the theory, how do we actually do that in a shader.

First, we need to process the vertex position in the vertex shader. We need its position in clip-space, in most of the case we already do that with `UnityObjectToClipPos()` and assign it `v2f.vertex`.

Once we have a clip-space vertex position we use `ComputeScreenPos()` to process this clip-space position and assign it to `v2f.shadowcoord`.

```c#
v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    UNITY_TRANSFER_FOG(o,o.vertex);
    
    // Process vertex clip-space position with ComputeScreenPos()
    o.shadowCoord = ComputeScreenPos(o.vertex);

    return o;
}   
```

Based on its name we could think `ComputeScreenPos()` directly return a screen coordinate that is either an NDC or already a UV coordinate but its name is misleading. `ComputeScreenPos()` will return a screen-space coordinate with a range is remapped from [-w,w] to [0,w]. This means the output vector stored in `v2f.shadowcoord` is not yet UV coordinate.

> To better understand `ComputeScreenPos()`, here is the code performed by the function:
>
>```c#
>float4 ComputeScreenPos(float4 clipPos)
>{
>   float4 o = clipPos * 0.5;
>#if defined(UNITY_HALF_TEXEL_OFFSET)
>   o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w * _ScreenParams.zw;
>#else
>   o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w; // use _ProjectionParams.x to flip V coordinate
>#endif
>   o.zw = clipPos.zw;
>   return o;
>}
>```

**Additional informations on the code used inside `ComputeScreenPos()`**:

>`_ProjectionParams` is an internal variable that we use to take several platform into account. For example, Direct3D and OpenGL don't use the same UV coordinate: 0,0 is the top-left corner with Direct3D and bottom-left corner with OpenGL so we use `_ProjectionParams.x` to flip the V coordinate.
>
> **_ProjectionParams parameters:**
> - `_ProjectionParams.x` = 1 or -1 depending on platform (for platform like Direct3D that use flipped transformation matrix)
> - `_ProjectionParams.y` = Znear camera values
> - `_ProjectionParams.z` = Zfar camera values
> - `_ProjectionParams.w` = 1/Zfar

> `UNITY_HALF_TEXEL_OFFSET` is a macro that is enabled on platform that need mapping displacement adjustement, we can combine it with `_ScreenParams` internal variable that keep the screen informations to take into consideration half-texel offset.
>
> **_ScreenParams parameters:**
> - `_ScreenParams.x` = width of the camera’s target texture in pixels
> - `_ScreenParams.y` = y is the height of the camera’s target texture in pixels
> - `_ScreenParams.z` = 1 + 1 / width
> - `_ScreenParams.w` = 1 + 1 / height

### Sample the shadow map with v2f.shadowcoord

As we said previously, the vector4 stored inside `v2f.shadowcoord` is a screen-space coordinate and not a UV coordinate. If we want to sample our shadow map we have two solutions:

1. Convert screen-space coordinate to UV coordinate

Our screen-space coordinate has a range of [0,w], this means we can simply divide its X and Y component by W to finally remap the value to a range of [0,1] and get actual UV coordinate.

```c#
fixed4 frag (v2f i) : SV_Target
{
    fixed4 col = tex2D(_MainTex, i.uv);
    
    // create shadow uv coord
    float2 uv_shadow = i.shadowCoord.xy / i.shadowCoord.w; // XY screenPos / W = UV coordinate
    
    // sample shadow map texture
    fixed shadow  = tex2D(_ShadowMapTexture, uv_shadow).a;
    
    // Apply shadow to object color
    col.rgb *= shadow;
    
    UNITY_APPLY_FOG(i.fogCoord, col);
    return col;
}
```

2. Sample the texture with `tex2Dproj()`

The other possibility is to sample the texture with `tex2Dproj()` instead of `tex2D()`. When using `tex2Dproj()` we provide our screen-space `float4` as coordinate and the function itself will divide X and Y by W to get the actual UV coordinate to sample the texture.

```c#
fixed4 frag (v2f i) : SV_Target
{
    fixed4 col = tex2D(_MainTex, i.uv);
    
    // Sample with tex2Dproj() and provide the full screenPos float4 as coordinate
    fixed shadow  = tex2Dproj(_ShadowMapTexture, i.shadowCoord).a;
    
    // Apply shadow to object color
    col.rgb *= shadow;
    
    UNITY_APPLY_FOG(i.fogCoord, col);
    return col;
}
```

> On most of the platform `tex2Dproj()` is no longer implemented in the hardware, it's just a wrapper for `tex2D()` and doesn't incur any performance improvement but it still a good pratice to use it to reduce user error.

## Optimized shadow map pass with macro

The process of implementing a shadow map can be simplified a lot by using the macro included with Unity. However, to use these specific macro we need to include a new cginc file called **AutoLight.cginc**.

```c#
#include "AutoLight.cginc"
```

We also need to declare a new pragma directive to compile all the lightmaps and shadow variants produced by the directional for the *ForwardBase* pass.

This directive is `#pragma multi_compile_fwdbase`, it is usually followed by optional parameter that allows to add or remove features in the shadow behavior. Here we add the optional parameters `nolightmap`, `nodirlightmap`, `nodynlightmap` and `novertexlight`.

```c#
#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
```

### Inputs and Outputs

For the inputs and outputs, due to the use of macro we need to rename some of the inputs and outputs we declare otherwise some macro won't compile correctly.

In the inputs we must rename **uv** (`float2 uv : TEXCOORD0;`) to **texcoord** (`float2 texcoord : TEXCOORD0;`).

In the outputs we must rename **vertex** (f`loat4 vertex : SV_POSITION;`) to **pos** (`float4 pos : SV_POSITION;`). We also need to add the `SHADOW_COORDS()` to tell where to store the shadow coordinate.

```c#
struct appdata
{
    float4 vertex : POSITION;
    float2 texcoord : TEXCOORD0; // "float2 uv : TEXCOORD0;" must be renamed to "texcoord"
};

struct v2f
{
    float2 uv : TEXCOORD0;
    
    SHADOW_COORDS(1) // Store shadow uv coord in TEXCOORD1 (no ; at the end)
    
    float4 pos : SV_POSITION; // "float4 vertex : SV_POSITION;" must be renamed to "pos"
};
```

### Process shadow map coordinate

To process the shadow map coordinate and pass them to the fragment shader we simply have to call the macro `TRANSFER_SHADOW()`.

```c#
v2f vert (appdata v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex); // new name = o.pos
    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex); // new name = v.texcoord
    
    // Transfer Shadow uv coordinates to fragment shader (equivalent of ComputeScreenPos())
    TRANSFER_SHADOW(o) // no ";" at the end of statement
    
    return o;
}
```

### Sample the shadow map

To sample the shadow map we just have to call the macro `SHADOW_ATTENUATION()` and store the result in a fixed that will multiply the pixel rgb color to apply the shadows.

```c#
fixed4 frag (v2f i) : SV_Target
{
    fixed4 col = tex2D(_MainTex, i.uv);
    
    // Sample and project shadow from shadow map texture
    fixed shadow = SHADOW_ATTENUATION(i);
    
    // Apply shadow on the object
    col.rgb *= shadow;
    
    UNITY_APPLY_FOG(i.fogCoord, col);
    return col;
}
```