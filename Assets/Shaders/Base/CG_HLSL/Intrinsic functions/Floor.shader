// Shader that use Floor() intrinsic function to show how it works

// Intrinsic functions are CG/HLSL functions that does mathematical operations and help you to produce some effects. Like the word
// intrinsic suggest they are available without any include both in CG and HLSL 

// See https://developer.download.nvidia.com/CgTutorial/cg_tutorial_appendix_e.html
// See https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-intrinsic-functions

// Floor

// -> Floor() return the biggest integer that is not more than the input argument.
// -> Ex:
//      - Floor(1.2) = 1
//      - Floor(4.97) = 4

// -> Floor() can be used to create effect with solid blocks of color like toon shader or to repeat pattern.

// -> In this shader we use Floor() to create the base of a toon shader effect

Shader "LearnShader/BIRP_Unlit/CG_HLSL/Intrinsic Functions/Floor"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // Toon properties
        [IntRange] _Sections ("Sections", Range(2,10)) = 5
        _Gamma ("Gamma", Range(0,1)) = 0
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
            
            float _Sections;
            float _Gamma;

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
                // Principle of toon shader is the name we just use the global illumination instead of the uv.v coordinate
                float vFloored = floor(i.uv.y * _Sections); // multiply uv.v by the number of color section to draw and floor the result
                vFloored *= (_Sections / 100.0); // Lower the value to revert surexposition (vFloored may be bigger than 1)
                
                fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb *= vFloored; // mulyiply by floored color

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col + _Gamma;
            }
            ENDCG
        }
    }
}
