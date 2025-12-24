// Shader that use Length() intrinsic function to show how it works

// Intrinsic functions are CG/HLSL functions that does mathematical operations and help you to produce some effects. Like the word
// intrinsic suggest they are available without any include both in CG and HLSL 

// See https://developer.download.nvidia.com/CgTutorial/cg_tutorial_appendix_e.html
// See https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-intrinsic-functions

// Length

// -> Length() return the euclidian length of a vector.

// -> Length() is useful to create geometric shapes like circle or polygonal shapes with rounded edges.

// -> In this shader we use Length() to create a circle shape

Shader "LearnShader/CG_HLSL/Intrinsic Functions/Length (BIRP_Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // Length properties
        _Radius ("Radius", Range(0.0, 0.5)) = 0.3
        _CenterU ("Center U", Range(0.0, 1.0)) = 0.5
        _CenterV ("Center V", Range(0.0, 1.0)) = 0.5
        _Smooth ("Smooth", Range(0.0, 0.5)) = 0.01
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            float _Radius;
            float _CenterU;
            float _CenterV;
            float _Smooth;
            
            // Calculate magnitude of a vector and substract the radius
            float Circle(float2 p)
            {
                float2 center = float2(_CenterU, _CenterV);
                float c = length(p - center) - _Radius;
                float minSmooth = c - _Smooth;
                float maxSmooth = c + _Smooth;
                return smoothstep(minSmooth, maxSmooth, _Radius);
            }
            
            float CircleNotCentered(float2 p)
            {
                float c = length(p) - _Radius;
                return c;
            }
            
            float CircleCentered(float2 p)
            {
                float2 center = float2(_CenterU, _CenterV);
                float c = length(p - center) - _Radius;
                return c;
            }

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
                float circle = Circle(i.uv);
                
                fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb *= circle;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
