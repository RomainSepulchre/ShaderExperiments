// Shader with annotation on CGPROGRAM

// ! Current up-to-date documentation is on HLSL language but most of the concept remains the same: 
// See https://docs.unity3d.com/6000.3/Documentation/Manual/writing-shader-writing-shader-programs-hlsl.html

Shader "LearnShader/BIRP_Unlit/CG_HLSL/CgProgram"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            // CGPROGRAM / HLSLPROGRAM

            // -> All sections before CGPROGRAM and after ENDCG (or HLSLPROGRAM / ENDHLSL for an HLSL shader) are written in shaderLab declarative
            //    language and all the code inside ...PROGRAM and END... is pure CG/HLSL code that compile the shader.
            // -> If CG is still compatible with BIRP, HLSL is now the official shader programming language in Unity. To update the shader to HLSL,
            //    we can simply replace CGPROGRAM and ENDCG by HLSLPROGRAM and ENDHLSL. The shader will then compile both in BIRP and SRP. However,
            //    if we want to update the program itself to HLSL this need way more work and changes.

            //CGPROGRAM
            HLSLPROGRAM
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
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDHLSL
            //ENDCG
        }
    }
}
