# Fresnel Effect

**Links:**

- https://kylehalladay.com/blog/tutorial/2014/02/18/Fresnel-Shaders-From-The-Ground-Up.html
- https://docs.unity3d.com/Packages/com.unity.shadergraph@6.9/manual/Fresnel-Effect-Node.html

## What is the Fresnel Effect ?

<img src="https://www.keheka.com/content/images/2023/04/Fresnel_Matte.jpg" alt="Screenshot of a fresnel effect" width="400"/>

The fresnel effect is a type of reflection where its size is proportional to the incidence angle (the angle between the object normals and the camera direction). The fresnel effect create a reflection on the rim of the object.

The more the surface is far from the camera, the more fresnel reflection we will have because the angle between the incidence value and the object normal increase when the surface get further from the camera.

When the angle between the incidence value and the normal equals 0° there is no reflection because the vectors are parallel and when the angle is 90° the reflection will be full because the vectors are perpendicular. This is very handy because in term of colors we must return black when the reflections are null and white when the reflection is full.

## How to calculate a fresnel effect ?

The shader graph node that calculate the fresnel effect use the following function:

```c#
void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
{
    Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
}
```

If we decompose what is happening in the function we have 3 steps:

1. We determine the angle between the incidence vector and the surface normal and we use `saturate()` to clamp the result value between 0 and 1.
2. A dot product return 1 when the vectors are parallel and 0 when they form a right-angle so we need to flip the result to have black (0) when there are parallel and white (1) when we have a right-angle.
3. We use `pow()` to control the range of the reflection by changing the value of the exponent.

```c#
void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
{
    float sat = saturate(dot(normalize(Normal), normalize(ViewDir))); // 1.
    float oneMinusSat = 1.0 - sat; // 2.
    Out = pow(oneMinusSat, Power); // 3.
}
```

> `saturate()` is simply a `clamp()` function where the limit values are set to 0 and 1.

## Implement fresnel effect in a shader

So, if we want to add fresnel effect to our shader we need to get 3 informations:
- the *normal of the surface*
- the *direction of the view*
- the *the power exponent that define the range of he fresnel effect*.

We can also add a *fresnel intensity* property to control the intensity of the effect.

### Fresnel power exponent and Fresnel intensity

Those 2 parameters are properties that we need to add to our shader.

```c#
Properties
{
    _MainTex ("Texture", 2D) = "white" {}
    
    // Fresnel effect properties
    _FresnelPow ("Fresnel Power", Range(1,5)) = 1
    _FresnelInt ("Fresnel Intensity", Range(0,1)) = 1
}
```

We also need to declare a connection variable inside CGPROGRAM to be able to use the properties later in the code.

```c#
CGPROGRAM
// Pragma and include
...

// Appdata and v2f struct
...

// Fresnel properties connection variables
float _FresnelPow;
float _FresnelInt;

// AmbientReflection(), vert() and frag()
...

ENDCG
```

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

### Calculate and apply the fresnel effect

Now that we have everything we need, we can calculate and apply the fresnel effect inside the fragment shader.

```c#
fixed4 frag (v2f i) : SV_Target
{
    fixed4 col = tex2D(_MainTex, i.uv);
    
    // Fresnel parameters
    float3 normal = i.normal_world;
    float3 viewDir = normalize(UnityWorldSpaceViewDir(i.vertex_world));
    float fresnel = 0;
    
    // Calculate fresnel reflection
    Unity_FresnelEffect_float(normal, viewDir, _FresnelPow, fresnel);
    
    // Ass fresnel reflections
    col += fresnel * _FresnelInt;
    
    UNITY_APPLY_FOG(i.fogCoord, col);
    return col;
}
```