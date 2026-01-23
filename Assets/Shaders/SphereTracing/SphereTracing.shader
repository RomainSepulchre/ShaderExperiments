Shader "LearnShader/Sphere Tracing/SphereTracing"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _PlaneTex ("Plane Texture", 2D) = "white" {}
        
        _CircleColor ("Circle Color", Color) = (1,1,1,1)
        
        _Edge ("Edge", Range(-0.5, 0.5)) = 0.0 // 0.5 correspond to the radius of the sphere on Y axis (-0.5 is the bottom of the sphere, 0 the middle and 0.5 the top)
        _CircleRadius ("Circle Radius", Range(0.0 ,0.5)) = 0.45
        
        _TexScale ("Texture scale", Range(0.0,10)) = 1.0
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
            sampler2D _PlaneTex;
            float4 _CircleColor; 
            
            float _Edge;
            float _CircleRadius;
            
            float _TexScale;
            
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
                
                // Project plane texture onto the plane positionby calculating uv for the plane
                float4 planeCol = 0;
                float4 circleCol = 0;
                if (t < MAX_DISTANCE)
                {
                    // Calculate spatial point of the plane
                    float3 p = rayOrigin + rayDirection * t;
                    // Our plane is poiting toward positive Y axis, so the texture must be oriented in the opposite direction. We can get uV coordiantes inside the sphere casting area with p.xz
                    float2 uv_p = p.xz;
                    
                    // Offset UV to center texture
                    //uv_p += 0.5; // center texture for 0 on Y
                    
                    // TODO: FIX ISSUE WITH TEXTURE SIZE SYNCHRONYZED WITH _Edge
                    // -> https://mathworld.wolfram.com/SphericalCap.html
                    // -> https://www.editions-petiteelisabeth.fr/calculs_aire_calotte_spherique.php
                    // -> I tried a few things the past days by using the area of the sphere disc and the spherical cap but nothing really works so I keep the original code despite it's not working as expected
                    // Scale texture to keep the projection size synchronized with _Edge
                    float l = pow(-abs(_Edge), 2) + pow(-abs(_Edge) - 1, 2);
                    
                    float c = length(uv_p);
                    circleCol = (smoothstep(c - 0.01, c + 0.01, _CircleRadius - abs(pow(_Edge * (1 * 0.5), 2))));
                    
                    uv_p = (uv_p * (1 - abs(pow(_Edge * l, 2)))); // ??? Error with this
                    uv_p *= _TexScale;
                    uv_p += 0.5; // Center texture
                    
                    // Sample plane texture
                    planeCol = tex2D(_PlaneTex, uv_p);
                    
                    // Apply circle radius color to plane texture
                    planeCol *= circleCol; // delete texture border
                    planeCol += (1 - circleCol) * _CircleColor; // Add circle and apply color
                }
                
                if (i.hitPos.y > _Edge) discard; // discard is a command that allows to delete the pixel on the rendering
                
                return face ? col : planeCol; // for back face return plane position as a color
            }
            ENDCG
                    
        }
    }
}
