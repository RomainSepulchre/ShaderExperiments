Shader "LearnShader/Sphere Tracing/SphereTracing"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Edge ("Edge", Range(-0.5, 0.5)) = 0.0 // 0.5 correspond to the radius of the sphere on Y axis (-0.5 is the bottom of the sphere, 0 the middle and 0.5 the top)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off // Disable culling to render both face 

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

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
                float3 hitPos : TEXCOORD1; // Used to define position of the mesh vertices and to calculate the spatial position of the plane
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            float _Edge;
            
            // Constant (#define allows to set constant variable)
            #define MAX_MARCHING_STEPS 50 // Max steps to determine surface intersection
            #define MAX_DISTANCE 10.0 // Maximum distance to find surface intersection
            #define SURFACE_DISTANCE 0.001 // Distance of the surface 
            
            
            // Function to calculate the position of the plane we want to define with sphere tracing
            float planeSDF(float3 rayPosition)
            {
                // Substract edge to y ray position to increase/decrease the plane position
                float plane = rayPosition.y - _Edge;
                return plane;
            }
            
            float sphereCasting(float3 rayOrigin, float3 rayDirection)
            {
                float distanceOrigin = 0;
                for (int i = 0; i < MAX_MARCHING_STEPS; i++)
                {
                    float3 rayPosition = rayOrigin + rayDirection * distanceOrigin;
                    float distanceScene = planeSDF(rayPosition);
                    distanceOrigin += distanceScene;
                    
                    if (distanceScene < SURFACE_DISTANCE || distanceOrigin > MAX_MARCHING_STEPS) break;
                        
                }
                
                return distanceOrigin;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.hitPos = v.vertex; // Assign vertex position in Object-Space
                return o;
            }

            fixed4 frag (v2f i, bool face : SV_IsFrontFace) : SV_Target // use SV_IsFrontFace semantic to have a different render for front and back face
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                // Get camera position in Object-space
                float3 rayOrigin = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                
                // Calculate ray direction
                float3 rayDirection = normalize(i.hitPos - rayOrigin);
                
                // Calculate position of the plane
                float t = sphereCasting(rayOrigin, rayDirection);
                
                // Calculate spatial point of the plane
                float3 p = rayOrigin + rayDirection * t;
                
                if (i.hitPos.y > _Edge) discard; // discard is a command that allows to delete the pixel on the rendering
                
                return face ? col : float4(p, 1); // for back face return plane position as a color
            }
            ENDCG
        }
    }
}
