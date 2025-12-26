# Normal maps

**Links:**

- https://medium.com/@onlyashley04/writing-a-basic-shader-in-unity-aa7396514daa
- https://docs.unity3d.com/6000.3/Documentation/Manual/StandardShaderMaterialParameterNormalMap.html

## Normal mapping

Normal mapping is a technique that generate surface details without the need of adding more vertices. To do that we provide a texture called a normal map and we use the color information of the texture pixels to change the direction of the normal and simulate light bouncing on a volume.

To change the direction of the normal we need to store all vertices within a space coordinate called *tangent-space* that is used for the objects surface lighting calculation. To convert coordinate to *tangent-space* we need to use a **TBN matrix** that is formed of 3 normalized vectors: *T* for **Tangent**, *B* for **Binormal** and *N* for **Normal**. Just like we use `unity_ObjectToWorld` matrix to convert *object-space* coordinates to *world-space* coordinates, we use the **TBN matrix** to convert *world-space* coordinates to *tangent-space*.

Representation of TBN matrix:

```c#
float4x4 TBN = float4x4
(
    Tx, Ty, Tz, 0, // Tangent values
    Bx, By, Bz, 0, // BiNormal values
    Nx, Ny, Nz, 0, // Normal values
    0,  0,  0,  0,
);
```

## Use a normal map texture in a shader

### Declare a normal map texture property

If we want to be able to assign a normal map texture in the inspector we need to declare a texture property for the normal map. We also add connection variables for the property to be able to use it in the sahder code.

```c#
Shader "..."
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // Normal map texture property
        _NormalMap ("Normal Map", 2D) = "white" {}
    }
    SubShader
    {
        ...

        Pass
        {
            CGPROGRAM
            
            ...

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            // Add connection variables for normal map property
            sampler2D _NormalMap;
            float4 _NormalMap_ST;

            ...
            ENDCG
        }
    }
}
```

### Get vertex normal and tangent value in vertex input (appdata)

If we want to use a TBN matrix we must get the *normal* and *tangent* in vertex input (`appdata`). To do that we bind a `float3` to **NORMAL** semantic and `float4` to **TANGENT** semantic.

```c#
struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    
    // To be able to build a TBN Matrix, we get the normal and tangent in vertex input
    float3 normal : NORMAL; // we bind a float3 to NORMAL semantic
    float4 tangent : TANGENT; // we bind a float4 to TANGENT semantic
};
```

>⚠️ At this stage *normal* and *tangent* are both in *object-space*, we will need to convert them to *world-space* before converting them to *tangent-space*.

### Set normal, tangent and binormal in vertex output (v2f)

In the vertex shader stage (`vert()`) we will calculate the world-space coordinate of the *tangent*, the *binormal* and the *normal* and we need to pass the result to the fragment shader stage (`frag()`). To do that we need to add new variables in the vertex output (`v2f`) that will store the calculated values.

**NORMAL** and **TANGENT** semantics are not avaialble in the vertex output (`v2f`) so instead we need to use another semantic that can store up to 4 dimensions. Usually, a good solution is to use **TEXCOORD** semantic with an incremented id: **TEXCOORD1**, **TEXCOORD2**, **TEXCOORD3**, ...

```c#
struct v2f
{
    float2 uv : TEXCOORD0;
    UNITY_FOG_COORDS(1)
    float4 vertex : SV_POSITION;
    
    // We need to declare in the vertex ouput the values we want to pass from vert() to frag()
    // -> No NORMAL or TANGENT semantic in v2f so we use TEXCOORD[n] instead
    float2 uv_normal : TEXCOORD1; // uv coordinate of the normal map texture
    float3 normal_world : TEXCOORD2; // normal coordinate in world-space
    float4 tangent_world : TEXCOORD3; // tangent coordinate in world-space
    float3 binormal_world : TEXCOORD4; // binormal coordinate in world-space
};
```

### Process Normal and Tangent in vertex shader stage (vert())

Inside the vertetx shader stage (`vert()`) we need to process the *Tangent* and the *Normal* to calculate the *Binormal*. Then, we can convert them to their world-space coordinates and finally we connect the values to `v2f` to pass the result to the fragment shader.

To calculate the world-space coordinates of the *normal* and *tangent* we simply need to use the `unity_ObjectToWorld` matrix.

To calculate the binormal we do a cross product between the normal and the tangent world-space coordinates we just calculated. Since we use world-space coordinates in the cross product, the result will be the binormal coordinate in world-space. To ensure the binormal orientation correspond to the orientation defined in the mesh, we also multiply the result of the cross product by W component of the object-space tangent coordinate () 

```c#
v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    UNITY_TRANSFER_FOG(o,o.vertex);
    
    // Tilling and offset of the normal map texture
    o.uv_normal = TRANSFORM_TEX(v.uv, _NormalMap);
    
    // Transform normal and tangent to world-space
    o.normal_world = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0)));
    o.tangent_world = normalize(mul(unity_ObjectToWorld, v.tangent));
    
    // Use a cross product to calculate binormal world-space coordinates using the normal and tangent world-space coordinates
    // -> multiply cross product result by v.tangent.w to ensure the binormal has a correct orientation
    o.binormal_world = normalize(cross(o.normal_world,o.tangent_world) * v.tangent.w);
    
    return o;
}
```

>⚠️ With Direct3D 11 it might be necessary to initialize `v2f` at 0 to carry out normals calculation in the shader. When it happens an error *Output value 'vert' is not completely initialized* is triggered.  
>  
>The solution is to use the macro **UNITY_INITIALIZE_OUTPUT** in the vertex shader:
> ```c#
>   v2f vert (appdata v)
>   {
>       v2f o;
>       UNITY_INITIALIZE_OUTPUT (v2f, o); // Initialize v2f
>       ...
>   }
> ```

<br>
<br>
<br>

 🚧 Still work in progress

<br>
<br>
<br>

<!-- I NEED TO REARRANGE THIS: maybe a UnpackNormal section with this and DXT compression ? -->

### Remap normal map RGBA value

When using the normal map texture value in the fragment shader, the X,Y,Z,W coordinates of the normal map are embedded in RGBA channels that range from [0 to 1]. Since a normal use value from [-1 to 1] we need to remap the numerical range from [0 to 1] to [-1 to 1].

> **normalMap.rgb** => **[0 to 1]**  
> **normalMap.rgb \* 2** => **[0\*2 to 1\*2]** == **[0 to 2]**  
> **(normalMap.rgb \* 2) - 1** => **[0-1 to 2-1]** == **[-1 to 1]**  

```c#
normalMap.rgb = normalMap.rgb * 2 - 1; // Remap RGB value from [0 to 1] to [-1 to 1] to use them as normal XYZ value
```

### DXT compression

A normal map texture is more heavy than a common texture and produce a significant graphic load on the GPU. To reduce its impact on performance, it is essential to compress the texture within the shader (especially on mobile device, where increased graphic lead can generate bettery overheating and affect user experience).

<!-- I NEED TO CLARIFY THIS BETTER AND CLEAN THE NOTES -->

DXT compression is one of the most used compression for normal maps. It divide the texture into blocks of 4 by 4 which are minimized using only the A and G channels. This allows a normal map to reduce its resolution to 1/4 of its original resolution.

 - Check if DTX compatible, if not fallback to uncompressed value (we also remap RGB value to [-1 to 1])
 - Compression:
    - Replace R channel by Alpha channel and remap value to [-1 to 1]
    - Keep G channel and remap value to [-1 to 1]
    - Replace B channel by `sqrt( 1 - (pow(normalCol.r, 2) + pow(normalCol.g, 2)) );`(= we calulate a new coordinate using A and G coordinates) 

```c#
float3 DXTCompression (float4 normalMap)
{
#if defined (UNITY_NO_DXT5nm) 

    // No compression, DTX5nm not supported
    // -> RGB value remap (normalMap.rgb * 2 - 1) is done here even if there is no compression 
    return normalMap.rgb * 2 - 1;

#else 

    // DTX Compression
    float3 normalCol;
    // Replace R channel by A channel and keep G channel
    normalCol = float3 (normalMap.a * 2 -1, normalMap.g * 2 - 1, 0); // RGB value remap is done on alpha and green channel before compression
    normalCol.b = sqrt( 1 - (pow(normalCol.r, 2) + pow(normalCol.g, 2)) ); // Calculate a new normalized vector with A  and G coordinates
    return normalCol;

#endif
}
```

<!-- THIS SHOULD BE MAIN INFO and Remap/DXT should sub-information that details what UnpackNormals does -->
--> Equivalent of UnpackNormal() from UnityCG.cginc 

### Create TBN matrix and use it in the fragment shader

To declare a TBN matrix, we simply declare a new float3x3 matrix. We follow the order defined by the TBN acronym to add the tangent, binormal and normal vector as a line inside the matrix.  

```c#
float3x3 TBN_3x3 = float3x3
(
    i.tangent_world.xyz,
    i.binormal_world,
    i.normal_world
);
```

If we need to build a 4x4 TBN matrix, the 4th component of our tangent, binormal and normal line is always 0 and the last line we add is 0 for every components.

```c#
float4x4 TBN_4x4 = float4x4
(
    i.tangent_world.xyz, 0,
    i.binormal_world, 0,
    i.normal_world, 0,
    0, 0, 0, 0
);
```

Now that we have defined our TBN matrix we can use it to convert the value of our normal map texture to tangent-space.

```c#
// Sample normal map texture
fixed4 normalMap = tex2D(_NormalMap, i.uv_normal);

// Compress and remap RGB value with UnpackNormal()
fixed3 normalCompressed = UnpackNormal(normalMap);

// Declare TBN matrix
float3x3 TBN = float3x3
(
    i.tangent_world.xyz,
    i.binormal_world,
    i.normal_world
);

// Convert normal map to tangent-space
normalMap = fixed4 (normalize(mul(TBN, normalCompressed )), 1);
```

