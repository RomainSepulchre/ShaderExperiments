// Shader that use Frac() intrinsic function to show how it works

// Intrinsic functions are CG/HLSL functions that does mathematical operations and help you to produce some effects. Like the word
// intrinsic suggest they are available without any include both in CG and HLSL 

// See https://developer.download.nvidia.com/CgTutorial/cg_tutorial_appendix_e.html
// See https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-intrinsic-functions

// Frac

// -> Frac() return only the decimals of the input
//      - frac(3.27) = 0.27
//      - frac(1.467) = 0.467

// -> Frac() is used to create noise, random repeating patterns ans much more.

// -> In this shader we use Frac() to create a circle shape

Shader "LearnShader/CG_HLSL/Intrinsic Functions/Frac (BIRP_Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        [Toggle] _EnableFrac ("Repeat texture with Frac", float) = 0
        _Size ("Size", Range(0.0, 0.5)) = 0.3
        _CenterU ("Center U", Range(0.0, 1.0)) = 0.5
        _CenterV ("Center V", Range(0.0, 1.0)) = 0.5
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
            
            #pragma multi_compile _ _ENABLEFRAC_ON

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
            
            float _Size;
            float _CenterU;
            float _CenterV;

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
                i.uv *= 3; // repeat uv
                float2 fracUV = frac(i.uv);            
                
                float2 center = float2(_CenterU, _CenterV);
                float circle = length(fracUV - center);
                float wCircle = floor(_Size / circle);
            #if _ENABLEFRAC_ON
                fixed4 col = tex2D(_MainTex, fracUV); // Use fracUV instead of i.uv to repeat clamped texture
            #else
                fixed4 col = tex2D(_MainTex, i.uv);
            #endif
                
                col.rgb *= clamp(wCircle, 0, 1); // Clamp value to prevent surexposition

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
