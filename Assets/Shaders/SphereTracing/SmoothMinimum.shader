Shader "LearnShader/Sphere Tracing/Smooth minimum"
{
    Properties
    {        
        _Position ("Circle Position", Range(0, 1)) = 0.5 // Position of circle B
        _Smooth ("Circle Smooth", Range(0.0, 1.0)) = 0.01 // Intensity of the circle edge smooth
        _CirclesInterpolation ("Circles Interpolation", Range(0.0, 0.5)) = 0.1
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
            };
            
            float _Position;
            float _Smooth;
            float _CirclesInterpolation;
            
            float smoothMinimum(float a, float b, float t)
            {
                float h = clamp(0.5 + 0.5 * (b - a) / t, 0.0, 1.0);
                return lerp(b, a, h) - t * h * (1.0 - h);
            }
            
            float circle(float2 pos, float radius)
            {
                float d = length(pos) - radius;
                return d;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {                
                float circleA = circle(i.uv,0.5);
                float circleB = circle(i.uv - _Position,0.2);
                float circlesMerged = smoothMinimum(circleA, circleB, _CirclesInterpolation);
                float circlesSmoothed = smoothstep(circlesMerged - _Smooth, circlesMerged + _Smooth, 0.0);
                float4 col = float4(circlesSmoothed.xxx, 1);
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
