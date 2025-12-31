# Diffuse Reflection

**Links:**

- https://en.wikipedia.org/wiki/Diffuse_reflection
- https://www.geeksforgeeks.org/computer-graphics/diffuse-reflection-in-computer-graphics/
- https://learnwebgl.brown37.net/09_lights/lights_diffuse.html
- https://en.wikipedia.org/wiki/Lambertian_reflectance
- https://www.scratchapixel.com/lessons/3d-basic-rendering/introduction-to-shading/diffuse-lambertian-shading.html

## What is a Diffuse reflection ?

Diffuse reflection is the reflection of light on a matte or glossy surface, the light is reflected in many direction. It compare the light source direction and the surface normal to define the illumination of the object.

![Representation of diffuse and specular reflection on a glossy surface](https://upload.wikimedia.org/wikipedia/commons/b/bd/Lambert2.gif)

In real-time 3D diffuse reflection follows Lambert model and obeys to *Lambert's cosine law* which describe how a matte surface reflect the light uniformally in all directions. This allows us to calculate how bright the surfaces of an object surface should be depending on the light source direction.

## How to calculate the diffuse reflection ?

The formula to calculate the diffuse reflection is:

$D = D_r * D_l * max(0, dot(n, l))$

or to simplify:

> *Diffusion* = *Reflection color of light source* ⋅ *light intensity* ⋅ max(0, dot(*surface normal*, *light direction*))

## Implement diffuse reflection in a shader

If we translate the formula to code, we can define a function that calculate the diffuse reflection:

```c#
float3 DiffuseShading(float3 ColorRefl, float lightInt, float3 normal, float3 lightDir)
{
    // D = Dr * Dl * max(0, dot(n, l))
    return ColorRefl * lightInt * max(0, dot(normal, lightDir));
}
```

So, if we want to add diffuse reflection to our shader we need to get 4 informations:
- the *reflection color of the light*
- the *light intensity*
- the *normal of the surface*
- the *direction of the light*

> ⚠️ The *normal* and the *light direction* must in world-space so we will need to make sure they are converted them from object-space to world-space. 

### Color Reflection

To define reflection color we can use `_lightColor[n]`. It is an internal variable that refers to the color of the scene lighting.

⚠️ To use `_lightColor[n]` we need to declare it as a uniform variable in the CGPROGRAM next to the connection variables. Once it is declared we can use it later in the code.

```c#
CGPROGRAM

// Pragma and include
...

// Appdata and v2f struct
...

// Connection variables
sampler2D _MainTex;
float4 _MainTex_ST;

// Internal variable
float4 _LightColor0; // internal variable that refers to scene lighting color

// DiffuseShading(), vert() and frag()
...

ENDCG
```

### Light Intensity

For the intensity of the light we can declare a property that will increase or decrease the intensity of light on our object.

```c#
Properties
{
    _MainTex ("Texture", 2D) = "white" {}
    
    // Property to control light intensity
    _LightInt ("Light Intensity", Range(0,1)) = 1
}
```

We also need to declare a connection variable inside CGPROGRAM to be able to use the property later in the code.

```c#
CGPROGRAM
// Pragma and include
...

// Appdata and v2f struct
...

// Connection variables
sampler2D _MainTex;
float4 _MainTex_ST;
float _LightInt; // Light intensity connection variable

// Internal variable
float4 _LightColor0; // internal variable that refers to scene lighting color

// DiffuseShading(), vert() and frag()
...

ENDCG
```

### Surface normal (world-space)

If we want to be able to get the normal we need to include it's semantic in the vertex input and output.

We declare a `float3` named *normal* inside `appdata` struct and we bind it to the semantic `NORMAL`.

```c#
struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL; // Get Normal
};
```

We also need to declare another `float3` in the output (`v2f` struct) to pass the normal value to the fragment shader. Since we will convert the normal to world-space inside `vert()` we call this `float3` *normal_world* and we bind it to the semantic `TEXCOORD1` since `NORMAL` is not available as an output semantic.

```c#
struct v2f
{
    float2 uv : TEXCOORD0;
    UNITY_FOG_COORDS(1)
    float4 vertex : SV_POSITION;
    float3 normal_world : TEXCOORD1; // Pass normal (in world-space) to fragment shader 
};
```

Finally, inside `vert()` we convert the normal to world-space and pass it to the fragment shader.

```c#
v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    UNITY_TRANSFER_FOG(o,o.vertex);
    o.normal_world = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0))).xyz; // Convert normal to world-space
    return o;
}
```

### Light direction (world-space)

To define the direction of the light in world-space we can use another internal variable `_WorldSpaceLightPos[n]`. Contrary to `_lightColor[n]` we don't have to declare it has a uniform variable because the variable is already initialized inside *UnityCG.cginc*.

```c#
float3 lightDir = normalize(_WorldSpaceLightPos0.xyz)
```

We normalize the vector to ensure it will have a magnitude of 1 and we store the X,Y and Z coordinates in a `float3`.

### Calculate and apply diffuse reflection

Now that we have everything we need, we can calculate and apply the diffuse reflection inside the fragment shader.

```c#
fixed4 frag (v2f i) : SV_Target
{
    fixed4 col = tex2D(_MainTex, i.uv);
    
    // Diffuse reflection parameter
    fixed3 colorRefl = _LightColor0.rgb; // _LightColor0 = scene lighting color
    float3 lightDir = normalize(_WorldSpaceLightPos0.xyz); // _WorldSpaceLightPos0 = direction of the directional light in world-space
    float3 normal = i.normal_world;
    
    // Calculate diffuse reflections value with DiffuseShading()
    half3 diffuse = DiffuseShading(colorRefl, _LightInt, normal, lightDir);
    
    // Include diffuse on texture
    col.rgb *= diffuse;
    
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