// Shader with comment to better understand ColorMask command in the SubShader section
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-SubShader-object.html
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-ColorMask.html

Shader "LearnShader/BIRP_Unlit/SubShader/ColorMask"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // ColorMask

        // -> Allows to limit the GPU to write only one or several of the RGBA channels when rendering an image.

        // -> ColorMask modes:
        //      - ColorMask 0 = Disable all channels
        //      - ColorMask R = only red channel
        //      - ColorMask G = only green channel
        //      - ColorMask B = only blue channel
        //      - ColorMask A = only alpha channel
        // -> Its also possible to mix several channels by combining them
        //      - ColorMask RG = only red and green channel
        //      - ColorMask BA = only blue and alpha channel
        //      - ColorMask RBA = only red, blue and alpha channel
        ColorMask RB
        
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
