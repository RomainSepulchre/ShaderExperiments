Shader "LearnShader/Sphere Tracing/Constructive Solid Geometry"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0 // Specify compile target, see https://docs.unity3d.com/2020.1/Documentation/Manual/SL-ShaderCompileTargets.html

            #include "UnityCG.cginc"
            
            // Uniform variables we pass from c# script
            uniform float4x4 _CamFrustumMatrix;
            uniform float4x4 _CamToWorldMatrix;
            uniform float _MaxDistance;
            uniform float4 _Sphere1;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray : TEXCOORD1; // store ray direction
            };

            v2f vert (appdata v)
            {
                v2f o;
                
                // Get index for frustum matrix
                half index = v.vertex.z;
                v.vertex.z = 0;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                
                // Get Ray and convert to world space
                o.ray = _CamFrustumMatrix[(int)index].xyz;
                o.ray /= abs(o.ray.z); // Normalize ray in its Z direction
                o.ray = mul(_CamToWorldMatrix, o.ray); // convert to world-space
                
                return o;
            }
            
            sampler2D _MainTex;
            
            float sdfSphere(float3 pos, float radius)
            {
                return length(pos) - radius;
            }
            
            float distanceField(float3 pos)
            {
                float sphere1 = sdfSphere(pos - _Sphere1.xyz, _Sphere1.w);
                return sphere1;
            }
            
            float3 getNormal(float3 hitPos)
            {
                const float2 offset = float2(0.001, 0.0);
                float3 normal = float3(
                    distanceField(hitPos + offset.xyy) - distanceField(hitPos - offset.xyy),
                    distanceField(hitPos + offset.yxy) - distanceField(hitPos - offset.yxy),
                    distanceField(hitPos + offset.yyx) - distanceField(hitPos - offset.yyx));
                
                return normalize(normal);
            }
            
            fixed4 raymarching(float3 rayOrigin, float3 rayDirection)
            {
                fixed4 result = fixed4(1,1,1,1);
                const int maxIteration = 64;
                float dist = 0; // distance travelled along the ray direction

                for (int i = 0; i < maxIteration; i++)
                {
                    if (dist > _MaxDistance) // Hit environment / skybox
                    {
                        result = fixed4(rayDirection, 1);
                        break;
                    }
                    
                    float3 rayPos = rayOrigin + rayDirection * dist;
                    float sdf = distanceField(rayPos); // Signed distance field (< 0 = inside something, > 0 outside something)
                    if (sdf < 0.01) // We hit something
                    {
                        // Shade object
                        float3 normal =  getNormal(rayPos);
                        float3 lightDir = _WorldSpaceLightPos0.xyz;
                        float light = dot(lightDir, normal); // dot product to know if the normal point toward the light or no
                        result = fixed4(1,1,1,1) * light;
                        break;
                    }
                    dist += sdf;
                }
                return result;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 rayDirection = normalize(i.ray.xyz);
                float3 rayOrigin = _WorldSpaceCameraPos;
                fixed4 result = raymarching(rayOrigin, rayDirection);
                return result;
            }
            ENDCG
        }
    }
}
