// Shader with comment to better understand AlphaToMask command in the SubShader section
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-SubShader-object.html
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-AlphaToMask.html

Shader "LearnShader/BIRP_Unlit/SubShader/AlphaToMask"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // AlphaToMask

        // -> AlphaToMask is a cheaper way to add a transparency effect. AlphaToMask applies a covering mask over the alpha channel that
        //    discard pixels depending on the alpha value. However, contrary to blending where the alpha values range from 0.0 to 1.0, with
        //    AlphaToMask the coverage mask can only assign values of 1 or 0 to the alpha channel. This means the transparency effect will be
        //    harsher. This is very useful for vegetation for example.
        // -> Another advantage of AlphaToMask is that contrary to blending you don't need to add the transparency tags (Queue and RenderType).
        //    As you can see in this example we use the Opaque RenderType.
        // -> Like Tags, AlphaToMask can be declared inside the subshader or inside a specific Pass.

        // -> AlphaToMask Modes:
        //      - On = Use the alpha as a mask to render only white pixels of the alpha channel.
        //      - Off (default value) = AlphaToMask is disabled

        AlphaToMask On

        // Note: AlphaToMask is compatible with BIRP and SRP.

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
