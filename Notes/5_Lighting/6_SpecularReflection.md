# Specular Reflection

**Links:**

- https://en.wikipedia.org/wiki/Specular_reflection

## What is a Specular reflection ?

The specular reflection define the way light is reflected in a specific direction, contrary to diffuse reflection which disperse light, the specular reflection create sharp reflection that depends on the angle of view.

<img src="https://upload.wikimedia.org/wikipedia/commons/b/bd/Lambert2.gif" alt="Representation of diffuse and specular reflection on a glossy surface" width="400"/>

In real-time 3D, Phong model adds specular reflections add a specular brightness to a surface according to the position of its normal.

## How to calculate the Specular reflection ?

The formula to calculate the specular reflection is:

$S = S_a * S_p * max(0, dot(H, N)^2)$

or to simplify:

> *Specular* = *Reflection color of light source* ⋅ *specular intensity* ⋅ max(0, dot(*halfway*, *surface normal*)^2)

The big difference between diffuse and specular reflections is the *H* vector we use in the calculation. It refers to a half vector called halfway.

We need *H* because if the specular reflection has the same angle as the light direction, we are only able to see the reflection when the camera is in the same direction. To solve this we calculate *H* to be an intermediate between the normal and the light direction, following the view direction.

$H = L + E / magnitude(L + E)$
> *Halfway* = *Light direction* + *view direction* / magnitude(*Light direction* + *view direction*)

Since we always use normalized vectors we can even simplify the operation:

$H = normalize(L + E)$
>Halfway = normalize(Light direction + view direction)

## Implement specular reflection in a shader

If we translate the formula to code, we can define a function that calculate the specular reflection:

```c#
float3 SpecularShading(float3 colorRefl, float specularInt, float3 normal, float3 lightDir, float3 viewDir, float specularPow)
{
    float3 h = normalize(lightDir + viewDir); // halfway
    
    return colorRefl * specularInt * pow(max(0, dot(normal, h)), specularPow);
}
```

So, if we want to add diffuse reflection to our shader we need to get 6 informations:
- the *reflection color of the light*
- the *specular intensity*
- the *normal of the surface*
- the *direction of the light*
- the *direction of the view*
- the *specularity exponent*

We also need to add a *specular texture map* to define where on the object the specular reflection should happen.

### Specular texture, specular intensity and specularity exponent

Those 3 parameters are properties that we need to add to our shader.

- *specular texture*: map that tells where there will be specular reflection
- *specular intensity*: define the intensity of the specular reflection
- *specular exponent*: control the size and the sharpness of the reflection (the more the value is ibg, the more the reflaction are small and sharp).


```c#
Properties
{
    _MainTex ("Texture", 2D) = "white" {}
    
    // Specular properties
    _SpecularTex ("Specular Texture", 2D) = "black" {} // black so no specular reflection added when there is no texture
    _SpecularInt ("Specular Intensity", Range(0,1)) = 1
    [IntRange] _SpecularPow ("Specular Power", Range(1, 128)) = 64
}
```

We also need to declare a connection variable inside CGPROGRAM to be able to use the properties later in the code.

```c#
CGPROGRAM
// Pragma and include
...

// Appdata and v2f struct
...

// Connection variables
sampler2D _SpecularTex;
float _SpecularInt;
float _SpecularPow;

// SpecularShading(), vert() and frag()
...

ENDCG
```

### Color Reflection

To define reflection color we need to sample the specular texture and multiply it by `_lightColor[n]` because we want to use the specular texture to map where the reflection are visible or not. 

```c#
CGPROGRAM
// Pragma and include
...

// Appdata and v2f struct
...

// Connection variables
sampler2D _SpecularTex;
float _SpecularInt;
float _SpecularPow;

// Internal variable
float4 _LightColor0; // declare _LightColor0 as a uniform variable

// SpecularShading() and vert()
...

fixed4 frag (v2f i) : SV_Target
{
    ...

    fixed3 specColorRefl = tex2D(_SpecularTex, i.uv) * _LightColor0.rgb;

    ...
}
ENDCG
```

> `_lightColor[n]` is an internal variable that refers to the color of the scene lighting.  
>  
> ⚠️ To use `_lightColor[n]` we need to declare it as a uniform variable in the CGPROGRAM next to the connection variables. Once it is declared we can use it later in the code.

### Surface normal and view direction (world-space)

#### Add inputs and outputs

If we want to be able to get the normal we need to include it's semantic in the vertex input and output. To calculate the view direction we also need the vertex position in world-space, it's already declared in the inputs so we only need to add it in the outputs.

In the inputs (`appdata` struct), we declare a `float3` named *normal* and we bind it to the semantic `NORMAL`.

```c#
struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL; // Get Normal
};
```

In the outputs (`v2f` struct) we need to declare two `float3` to pass the normal and the vertex position to the fragment shader. Since we will convert them world-space inside `vert()` we call them `float3` *normal_world* and *vertex_world* and we bind them to the semantic `TEXCOORD1` (`NORMAL` is not available as an output semantic) and `TEXCOORD2`.

```c#
struct v2f
{
    float2 uv : TEXCOORD0;
    UNITY_FOG_COORDS(1)
    float4 vertex : SV_POSITION;
    float3 normal_world : TEXCOORD1; // Pass normal (in world-space) to fragment shader
    float3 vertex_world : TEXCOORD2; // Pass vertex position (in world-space) to fragment shader
};
```

Finally, inside `vert()` we convert the normal and vertex position to world-space and pass it to the fragment shader.

```c#
v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    UNITY_TRANSFER_FOG(o,o.vertex);
    o.normal_world =  UnityObjectToWorldNormal(v.normal); // UnityObjectToWorldNormal() is a UnityCG.cginc function that does the normal object to world-space conversion
    o.vertex_world = mul(unity_ObjectToWorld, v.vertex); // convert vertex position to world-space
    return o;
}
```

#### Calculate view direction

To calculate the view direction in the fragment shader we substract the vertex position to the camera position (both in world-space). To get the position of the camera in world-space we use the internal variable `_WorldSpaceCameraPos`.

```c#
float3 viewDir = normalize(_WorldSpaceCameraPos - i.vertex_world); // Calculate view direction using camera position
```

>⚠️ `_WorldSpaceCameraPos` is initialized inside UnityCG.cginc so we don't need to declate it as a uniform variable to use it.

UnityCG.cginc also provide `UnityWorldSpaceViewDir()`, you pass the vertex position (in world-space) as argument and it return the view direction,

```c#
 half3 viewDir = normalize(UnityWorldSpaceViewDir(i.vertex_world)); // UnityWorldSpaceViewDir() is a UnityCG.cginc function that calculate view direction from vertex world position
```

### Light direction (world-space)

To define the direction of the light in world-space we can use another internal variable `_WorldSpaceLightPos[n]`. Contrary to `_lightColor[n]` we don't have to declare it has a uniform variable because the variable is already initialized inside *UnityCG.cginc*.

```c#
float3 lightDir = normalize(_WorldSpaceLightPos0.xyz)
```

We normalize the vector to ensure it will have a magnitude of 1 and we store the X,Y and Z coordinates in a `float3`.

### Calculate and add specular reflection

Now that we have everything we need, we can calculate and apply the specular reflection inside the fragment shader.

```c#
fixed4 frag (v2f i) : SV_Target
{
    fixed4 col = tex2D(_MainTex, i.uv);
    
    // Specular reflection parameters
    fixed3 specColorRefl = tex2D(_SpecularTex, i.uv) * _LightColor0;
    float3 normal = i.normal_world;
    float3 lightDir = normalize(_WorldSpaceLightPos0.xyz); // _WorldSpaceLightPos0 = internal variable that refers the direction of the directional light in world-space (initialized in UnityCG.cginc)
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.vertex_world); // Calculate view direction using camera position (_WorldSpaceCameraPos = internal variable that refers the camera position in world-space (initialized in UnityCG.cginc))
    
    // Calulate specular reflection
    half3 specular = SpecularShading(specColorRefl, _SpecularInt, normal, lightDir, viewDir, _SpecularPow);
    
    // Add specularity on the texture
    col.rgb += specular;
    
    UNITY_APPLY_FOG(i.fogCoord, col);
    return col;
}
```

Since reflection are a lighting pass, we also need to add a tag to configure the render path

```c#
Tags {
    "RenderType"="Opaque"
    "LightMode"="ForwardBase" // configure the render path to forward base
}
```