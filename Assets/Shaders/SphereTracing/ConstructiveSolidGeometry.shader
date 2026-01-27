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
            uniform float4 _CamWorldSpace; // we could also use _WorldSpaceCameraPos
            uniform float4x4 _CamFrustumMatrix;
            uniform float4x4 _CamToWorldMatrix;

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

            fixed4 frag (v2f i) : SV_Target
            {
                float3 rayDirection = normalize(i.ray.xyz);
                float3 rayOrigin = _CamWorldSpace;
                return fixed4(rayDirection, 1);
            }
            ENDCG
        }
    }
}
