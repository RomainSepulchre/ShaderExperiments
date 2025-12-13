// Shader for the object that is masked, mask the object when it is outside of the mask
// See https://docs.unity3d.com/6000.3/Documentation/Manual/SL-Stencil.html

Shader "LearnShader/Examples/Stencil/StencilExample_Masked_Out"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "Queue"="Geometry" }

        // We keep ZWrite active because this object need to be rendered according to its camera-relative position

        // Stencil command so the object can be masked
        Stencil
        {
            // StencilRef (value assigned to the stencil buffer)
            // -> We assign the same value we assigned in the mask shader to the StencilRef (2)
            Ref 2

            // Comp (comparison function used to define if the pixel must be drawn)
            // -> We use Equal so that the area of the object that is covered by mask will be rendered since the test will pass and the area
            //    that is around the mask will not be rendered since the test will fail.
            Comp Equal

            // Pass (Operation the GPU to perform on the Stencil Buffer when a pixel pases the stencil and depth test)
            // -> We use keep so the object maintains the current content of the stencil buffer
            Pass Keep
        }

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

                // Multiply texure with a red color to identify object with shader
                col *= fixed4(1,0,0,1);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
