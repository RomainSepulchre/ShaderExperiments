# Normals

**Links:**

- https://docs.unity3d.com/Manual/SL-HLSLSemantics.html
- https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-semantics

## Get normal data in the vertex input (appdata struct)

If we want to be able to use the normal of a vertex we first need to ge the normal information. By default the `appdata` struct only get the *vertex* and the *uv* data. To get the normal data we need to add a new `float3` variable binded to the **NORMAL** semantic.

```c#
struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    
    // Get normal data by bind a float3 to NORMAL semantic
    float3 normal : NORMAL;
};
```

> The 4th dimension of a vector (w component) tells if the vector is a direction (w=0) or a position (1). A normal is a direction so we use a vector3 and w component will be 0 by default.

## Set the normal vertex output (v2f struct)

Now that we have declared the normal in the vertex input (`appdata`), if we need to use it in the fragment shader we also need to declare it in the vertex output (`v2f`). To do that we need to declare a new `float3` variable but contrary to the one declared in `appdata` we can't use the semantic **NORMAL** because it doesn't exist for the fragment shader. So instead we can use another semantic that is also able to store a vector3. Usually the semantic **TEXCOORD1** is a good option since it is a vector4 and works great to process normals. 

```c#
struct v2f
{
    float2 uv : TEXCOORD0;
    UNITY_FOG_COORDS(1)
    float4 vertex : SV_POSITION;
    
    // Add a new float3 variable to store the normal and use TEXCOORD1 semantic since NORMAL semantic isn't available in fragment shader 
    float3 normal : TEXCOORD1;
};
```

## Pass the normal from vert() to frag()

To pass the normal data from the vertex shader (`vert()`) to the fragment shader (`frag()`) we simply need to connect the normal input (`appdata.normal`) to the normal output (`v2f.normal`) inside the vertex shader: `v2f.normal = appdata.normal`.

```c#
v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    UNITY_TRANSFER_FOG(o,o.vertex);
    
    // Connect the normal input (appdata) to the output (v2f)
    o.normal = v.normal; // Pass the normal in object space

    return o;
}
```

## Use normal in frag()

Now that we passed the normal to the fragment shader, inside `frag()` we can use the normal value we declared inside the `v2f` argument (`v2f.normal`). 

In the example below we use the normal value as a color to multiply our texture color.

```c#
fixed4 frag (v2f i) : SV_Target
{    
    // Use normals as color (we use abs() to make sure the color value will be positive)
    half3 light = abs(i.normal);
    
    fixed4 col = tex2D(_MainTex, i.uv);
    col.rgb *= light.rgb; // Multiply texture by normal as color
    UNITY_APPLY_FOG(i.fogCoord, col);
    
    return col;
}
```

## Convert normal from object-space to world-space

In the examples above we use the normal object-space coordinate, but usually for lighting calculation we need to use its world-space coordinates so we have to convert them from object-space to world-space.

To convert coordinates from object-space to world-space we simply have to multiply the object-space coordinates by `unity_ObjectToWorld` matrix. This matrix is part of the [built-in variables](https://docs.unity3d.com/6000.3/Documentation/Manual/SL-UnityShaderVariables.html) and allows to convert an object-space vector to world-space.

UnityCg.cginc provide `UnityObjectToWorldNormal()`, which is a function dedicated to convert normal from object-space to world-space.

```c#
UnityObjectToWorldNormal(normalToConvert);
```

However to better understand the operation we do to achieve the object to world space convertion, here is a simple function that convert the normal from object-space to world-space:

```c#
// Function to transform the normal from object to world space
half3 NormalObjToWorld(half3 normal)
{
    // Multiply the normal by the object to world matrice
    // -> we encapsulate the normal in a float4 because unity_ObjectToWorld is a float4x4 matrice so our normal vector must
    //    have 4 components. Normal W component is set to 0 because a normal is a direction.
    half4 worldNormal = mul(unity_ObjectToWorld, float4(normal, 0));  
    return normalize(worldNormal).xyz; // Normalize and return normal in world space  
}
```

Now that we have a function that convert our normal from object-space to world-space we can convert the normal space in our vertex shader (`vert()`) or in our fragment shader (`frag()`). However, it's more optimized to do the conversion it in `vert()` because the operation will be made once for each vertices while when doing it in `frag()`, the operation is made once for each pixels on the screen (which is usually a way larger amount of time).

```c#
v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    UNITY_TRANSFER_FOG(o,o.vertex);
    
    // Connect the normal input (appdata) to the output (v2f)
    o.normal = NormalObjToWorld(v.normal); // Convert the normal to world space and pass it to the fragment shader

    return o;
}
```

> 