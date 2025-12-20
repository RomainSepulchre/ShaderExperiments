# Cull

**Links:**

- https://docs.unity3d.com/6000.2/Documentation/Manual/SL-Cull.html

## Cull

The `cull` command allow you to control which face of a polygon will be removed when processing pixel depth. By default, the outer faces are rendered but the cull command can change that.

```c#
Shader
{
    Properties
    {
        ...
    }
    SubShader
    {
        ...
        Cull Back

        Pass
        {
            Cull Back // can be defined in a pass have a specific setting in it
            ...
        }
    }
}
```

### Cull modes

- `Cull Off` = Both faces are rendered
- `Cull Back` = Back faces are rendered (outside of the object) - default
- `Cull Front` = Front faces are rendered (inside of the object)

## SV_IsFrontFace

When `Cull` is set to Off it possible to use the semantic `SV_IsFrontFace` in `frag()` to paint different texture or color on both faces (front and back) of the mesh.

```c#
Shader "..."
{
    Properties
    {
        ...
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Cull Off // Disable Cull to use SV_IsFrontFace

        Pass
        {
            CGPROGRAM

            // Pragma, include, appdata and v2f struct,
            ...

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                ...
            }

            // Example : Use SV_IsFrontFace semantic to paint on both face
            fixed4 frag (v2f i, bool face : SV_IsFrontFace) : SV_Target // Add a bool argument and assign it SV_IsFrontFace semantic
            {
                // sample the texture
                fixed4 tex = tex2D(_MainTex, i.uv);

                // Define a color for front and back faces
                fixed4 frontCol = fixed4(1,0,0,1);
                fixed4 backCol = fixed4(0,0,1,1);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, tex);

                // Use the bool to define change output
                return face ? tex * frontCol : tex * backCol;
            }
            ENDCG
        }
    }
}
```