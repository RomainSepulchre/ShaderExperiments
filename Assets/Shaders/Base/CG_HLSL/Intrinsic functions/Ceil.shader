// Shader that use Ceil() intrinsic function how it works

// Intrinsic functions are CG/HLSL functions that does mathematical operations and help you to produce some effects. Like the word
// intrinsic suggest they are available without any include both in CG and HLSL 

// See https://developer.download.nvidia.com/CgTutorial/cg_tutorial_appendix_e.html
// See https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-intrinsic-functions

// Ceil

// -> Ceil return the smallest integer that is not less than the input argument.
// -> Ex:
//      - Ceil(.2) = 1
//      - Ceil(1.7) = 2
// -> Ceil() is useful to create effects like video game zoom or magnifying glass.
//      - Ceil the value of UV coordinates, multiply them by 0.5 and lerp between default uv and modified uv 

// -> In this shader we use Ceil() to zoom in our texture

Shader "LearnShader/BIRP_Unlit/CG_HLSL/Intrinsic Functions/Ceil"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // Zoom value property
        _Zoom ("Zoom", Range(0, 1)) = 0
        
        // Zoom center properties
        _ZoomCenterU ("U zoom center", Range(0,1)) = 0.5
        _ZoomCenterV ("V zoom center", Range(0,1)) = 0.5
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
            
            float _Zoom;
            float _ZoomCenterU;
            float _ZoomCenterV;

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
                // Ceil U and V value
                float u = ceil(i.uv.x) * _ZoomCenterU;
                float v = ceil(i.uv.y) * _ZoomCenterV;
                
                // Lerp uv value using zoom slider
                float uLerp = lerp(i.uv.x, u, _Zoom);
                float vLerp = lerp(i.uv.y, v, _Zoom);
                
                // sample the texture at lerped uv coordinate
                fixed4 col = tex2D(_MainTex, float2(uLerp,vLerp));

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
