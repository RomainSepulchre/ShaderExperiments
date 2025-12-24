// Annoted BIRP Unlit Shader converted to HLSL to make it compatible with URP with

// Convert shader to URP
// 1. Add the RenderPipeline Tag ("RenderPipeline"="UniversalRenderPipeline")
// 2. Convert the shader program to hlsl
// 3. Include HLSL core functions
// 4. Replace CG functions by HLSL functions
// 5. Set frag() return type to half4 or include HLSLSupport.cginc

// See https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@14.0/manual/urp-shaders/birp-urp-custom-shader-upgrade-guide.html

Shader "LearnShader/CG_HLSL/CG to HLSL (BIRP_Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // 1. Add the RenderPipeline Tag
        // -> To tell the GPU that the shader should be compatible with the render pipeline we add a new tag "RenderPipeline" and set his value
        //    to the pipeline we target.
        Tags
        {
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalRenderPipeline" // RenderPipeline Tag set to UniversalRenderPipeline because we target URP
        }
        LOD 100

        Pass
        {
            // 2. Convert the shader program to HLSL
            // -> As we already saw before the new render pipeline no longer use CG, we need to use HLSL instead. To do that that the first thing
            //    we need to do is to replace CGPROGRAM ... ENDCG by HLSLPROGRAM ... ENDHLSL to tell the GPU the code is HLSL.
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            // 3. Include HLSL core functions
            // -> "UnityCG.cginc" that we include in CG code gives us access to standard CG variables and functions to simplify our work. Since,
            //    we switch to HLSL we need to include "Core.hlsl" the HLSL equivalent of "UnityCG.cginc".
            // -> Contrary to "UnityCG.cginc", "Core.hlsl" is not included in the editor installation because it is part of the render pipeline
            //    package. To include it we need to write its full path in the package folder. 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //#include "UnityCG.cginc" // UnityCG.cginc is no longer needed since we will use the variable and functions from Core.hlsl

            // 5. Set frag() return type to half4 or include HLSLSupport.cginc
            // -> Rather than replacing all the fixed in our code we can also include HLSLSupport.cginc. It's a dependency that adds helper macros 
            //    and cross-platform definitions for shader compilation. When using it fixed are detected and automatically replaced by half
            //    or a float at compilation.
            #include "HLSLSupport.cginc"

            // 4. Replace CG functions by HLSL functions
            // -> Since we no longer use "UnityCG.cginc" we also need to replace all the CG functions we were using by their HLSL equivalent.
            //      - Remove UNITY_FOG_COORDS(), UNITY_TRANSFER_FOG(), UNITY_APPLY_FOG() they have no equivalent in HLSL
            //          -> ? How to handle Fog in HLSL ??? 
            //      - Replace UnityObjectToClipPos() -> TransformObjectToHClip()

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                // UNITY_FOG_COORDS(1) // Cannot compile in HLSL, UNITY_FOG_COORDS() is part of UnityCG.cginc
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex); // Replace UnityObjectToClipPos() with TransformObjectToHClip()
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // UNITY_TRANSFER_FOG(o,o.vertex); // Cannot compile in HLSL, UNITY_TRANSFER_FOG() is part of UnityCG.cginc
                return o;
            }

            // 5. Set frag() return type to half4 or include HLSLSupport.cginc
            // -> fixed4 is not compatible with HLSL so we need to replace it by half4
            // -> Another solution is to include HLSLSupport.cginc (#include "HLSLSupport.cginc"). It's a dependency that adds helper macros 
            //    and cross-platform definitions for shader compilation. When using it fixed are detected and automatically replaced by half
            //    or a float at compilation.
            fixed4 frag (v2f i) : SV_Target // We included HLSLSupport.cginc so we can keep fixed4
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv); // We included HLSLSupport.cginc so we can keep fixed4

                // UNITY_APPLY_FOG(i.fogCoord, col); // Cannot compile in HLSL, UNITY_APPLY_FOG() is part of UnityCG.cginc
                return col;
            }
            ENDHLSL
        }
    }
}
