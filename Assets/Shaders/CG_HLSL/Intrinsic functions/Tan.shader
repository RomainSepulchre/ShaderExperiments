// Shader that use Tan() intrinsic function to show how it works

// Intrinsic functions are CG/HLSL functions that does mathematical operations and help you to produce some effects. Like the word
// intrinsic suggest they are available without any include both in CG and HLSL 

// See https://developer.download.nvidia.com/CgTutorial/cg_tutorial_appendix_e.html
// See https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-intrinsic-functions

// Tan

// -> Tan() is trigonometry functions that return the tangent of an angle
//      - Tan() = Tangent (ratio of the opposite side to the adjacent side)
//      - See https://fr.wikipedia.org/wiki/Tangente_(trigonom%C3%A9trie)#/media/Fichier:Tangent-plot.svg

// -> Tan() is a very useful function in computer graphics, you can use it to generate geometric figures and repeat pattern.

// -> In this shader we use Tan() to generate a procedural grid-like mask that we use to simulate an holographic projection effect
//      - To do that we calculate the absolute value of the tangent at one of uv coordinates within the fragment shader

Shader "LearnShader/CG_HLSL/Intrinsic Functions/Tan (BIRP_Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _Color ("Color", Color) = (1,1,1,1)
        _Sections ("Sections", Range(2, 20)) = 10
        [PowerSlider(3)] _Fade ("Fade", Range(0,10)) = 1
    }
    SubShader
    {
        // Enable transparency
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        
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
            
            fixed4 _Color;
            float _Sections;
            float _Fade;

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
                // Calculate mask with tan(), use _Time.x to animate the pattern
                float4 tanCol = abs(tan((i.uv.y - _Time.x) * _Sections) * _Fade);
                
                // Clamp values between 0 and 1 to prevent saturation
                tanCol = clamp(tanCol, 0, 1);
                    
                // Add color to tan mask
                tanCol *= _Color;
                
                // Sample texture and multiply by tan mask
                fixed4 col = tex2D(_MainTex, i.uv) * tanCol;

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
