// Shader with annotation on Fallback block
// See https://docs.unity3d.com/6000.3/Documentation/Manual/SL-Fallback.html

Shader "LearnShader/BIRP_Unlit/Fallback"
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

    // Fallback

    // -> Fallback block helps to avoid GPU compilation error on the shader by providing another the path to another fallback shader to use 
    //    when the principal shader failed to compile.

    // -> On a multiplatform game it is recommended to specify a fallback shader to ensure it works on most devices.
    // -> When specifying a fallback shader it is usually recommended to use a shader that is included in the software to ensure the program
    //    continues to run correctly (Mobile/Diffuse, Mobile/Unlit for example or the standard BIRP/URP shader).

    // -> To specify the fallback shader we just need to write Fallback followed by the path of the shader to use as fallback. In the example
    //    below we use Mobile/Unlit shader as a fallback shader. So if any error happens when compiling the main shader, Mobile/Unlit shader
    //    will be used instead.
    Fallback "Mobile/Unlit"

    // Note: Not specifying the Fallback command or specifying Fallback Off allows to omit the command

}
