// Shader that shows how to configure normals input and output to work with lighting

// -> Configure normal and transform its coordinates from object space to world space

// -> See https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-semantics
// -> See https://docs.unity3d.com/Manual/SL-HLSLSemantics.html

Shader "LearnShader/Lighting/Normals (BIRP_Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Toggle] _UseWorldNormals ("Use world space normals", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma shader_feature _USEWORLDNORMALS_ON // Keyword for toggle property

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                
                // Inputs: Get normals
                // -> To get the objects normal we need to declare a float3 with the semantic normal
                // -> 4th dimension of a vector (w component) tells if the vector is a direction (w=0) or a position (1). Since the normal is a
                //    direction we use a vector3 and w component is 0 by default.
                float3 normal : NORMAL;
                
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                
                // Outputs: If we need to use the normal in the fragment shader we need to declare it in v2f to transfer it after vertex shader stage
                // -> ! According to HLSL documentation there is no NORMAL semantic for the fragment shader stage so instead we must use a semantic that
                //      able to store at least a vector3. TEXCOORD1 is a good option since it is a vector4 and works great to process normals.
                float3 normal : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            // Function to transform the normal from object to world space
            // -> Lighting calculation must be in world-space because incidence values are found in the scene and objects have a position relative to the
            //    center of the world
            half3 NormalObjToWorld(half3 normal)
            {
                // Multiply the normal by the object to world matrice
                // -> we encapsulate the normal in a float4 because unity_ObjectToWorld is a float4x4 matrice so our normal vector must
                //    have 4 components. Normal W component is set to 0 because a normal is a direction.
                half4 worldNormal = mul(unity_ObjectToWorld, float4(normal, 0));  
                return normalize(worldNormal).xyz; // Normalize and return normal in world space  
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                
                // Connect the normal input (appdata) to the output (v2f)
            #if _USEWORLDNORMALS_ON
                // -> Calculating the world space normal in vert() is more optimized because the operation is made for each vertices while when
                //    done in frag() the operation is made for each pixels on the screen.
                o.normal = NormalObjToWorld(v.normal); // Pass the normal in world space
            #else
                o.normal = v.normal; // Pass the normal in object space
            #endif
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // We can calculate the world space normal here but it's more optimized to do it in vert() because the operation will
                // be made for each vertices while when doing it in frag(), the operation is made for each pixels on the screen.
                
                // Use normals as color (we use abs() to make sure the color value will be positive)
                half3 light = abs(i.normal);
                
                fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb *= light.rgb; // Multiply texture by normal as color
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                return col;
            }
            ENDCG
        }
    }
}
