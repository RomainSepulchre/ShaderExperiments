Shader "LearnShader/CG_HLSL_Comparison/HLSL_URP_Unlit"
{
    Properties
    {
        // ? new property attribute
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
    }

    SubShader
    {
        // ? new tag to define render pipeline 
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            // ? no multi_compile fog pragma
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes // ? equivalent to appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings // ? equivalent to v2f
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // ? Connection variable equivalent
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap); // ? why/what is it

            CBUFFER_START(UnityPerMaterial) // ? Why/what is it
                half4 _BaseColor;
                float4 _BaseMap_ST;
            CBUFFER_END

            // Vertex 
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            // Framgent
            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;
                return color;
            }
            ENDHLSL
        }
    }
}
