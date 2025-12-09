// Shader with comment to better understand the SubShader section
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-SubShader-object.html
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-SubShaderTags.html
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-ShaderReplacement.html
// See https://docs.unity3d.com/6000.3/Documentation/Manual/SL-Blend.html

Shader "LearnShader/BIRP_Unlit/SubShader/SubShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    // SubShader
    // -> Each shader is composed of a least one subShader section. When there is several subshader, Unity process all of them from 
    //    the first to the last and choose the more suitable subshader for the current hardware characteritics.
    // -> If no subshader are supported Unity will try to use the Fallback component if it exist   
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
            ENDCG
        }
    }
}
