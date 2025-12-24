// Shader that use Clamp() intrinsic function to show how it works

// Intrinsic functions are CG/HLSL functions that does mathematical operations and help you to produce some effects. Like the word
// intrinsic suggest they are available without any include both in CG and HLSL 

// See https://developer.download.nvidia.com/CgTutorial/cg_tutorial_appendix_e.html
// See https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-intrinsic-functions

// Clamp

// -> Clamp allows to limit a value to a minimum and maximum. We provide a value, a minimum and a maximum and Clamp()
//    return a value that is limited to be between the min and max.
// -> Ex:
//      - Clamp(0.5, 0, 1) = 0.5
//      - Clamp(1.7, 0, 1) = 1
//      - Clamp(-2, 0, 1) = 0

// -> In this shader we use Clamp() to limit the gamma color of the texture to a min and max 

Shader "LearnShader/CG_HLSL/Intrinsic Functions/Clamp (BIRP_Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // Value, Min and Max
        _Value ("Gamma value", float) = 0
        _Min ("Minimum", float) = 0
        _Max ("Maximum", float) = 1
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
            // make fog work
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            float _Value;
            float _Min;
            float _Max;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float darkness = clamp(_Value, _Min, _Max);
                fixed4 col = tex2D(_MainTex, i.uv);
                col *= darkness;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
