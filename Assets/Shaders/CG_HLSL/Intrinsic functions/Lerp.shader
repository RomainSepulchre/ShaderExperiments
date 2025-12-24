// Shader that use Lerp() intrinsic function to show how it works

// Intrinsic functions are CG/HLSL functions that does mathematical operations and help you to produce some effects. Like the word
// intrinsic suggest they are available without any include both in CG and HLSL 

// See https://developer.download.nvidia.com/CgTutorial/cg_tutorial_appendix_e.html
// See https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-intrinsic-functions

// Lerp

// -> Lerp() let you do a linear interpolation between two values
//      - lerp(a, b, t): linear interpolation between the value of a and b based on the value of t 

// -> Lerp() can be used to make transitions between states like color transition.

// -> In this shader we use Lerp() to crossfade between two textures

Shader "LearnShader/CG_HLSL/Intrinsic Functions/Lerp (BIRP_Unlit)"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _SecTex ("Secondary Texture", 2D) = "white" {}
        
        _Lerp ("Lerp", Range(0, 1)) = 0.5
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
                
                // Create UV coordinates for main and secondary textures
                float2 uv01 : TEXCOORD0;
                float2 uv02 : TEXCOORD1;
            };

            struct v2f
            {
                // UV coordinates for main and secondary textures to use them in the fragment shader
                float2 uv01 : TEXCOORD0;
                float2 uv02 : TEXCOORD1;
                
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            sampler2D _SecTex;
            float4 _SecTex_ST;
            
            float _Lerp;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                // Add tilling and offset for every textures
                o.uv01 = TRANSFORM_TEX(v.uv01, _MainTex);
                o.uv02 = TRANSFORM_TEX(v.uv02, _SecTex);
                
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Sample main and sec texture with their own uv coordinates
                fixed4 mainTex = tex2D(_MainTex, i.uv01);
                fixed4 secTex = tex2D(_SecTex, i.uv02); // ? why do I have to tile texture to make it fit to it's original size 
                
                // Lerp between the two textures
                fixed4 col = lerp(mainTex, secTex, _Lerp);
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
