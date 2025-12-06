// Shader with custom property to show how connection variables works
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-Properties.html

Shader "LearnShader/BIRP_Unlit_ConnectionVariables"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        // Custom properties that need connection variables to be used in the CG or HLSL code
        _SecTex ("Secondary Texture", 2D) = "white" {}
        _MultColor ("Color", Color) = (0,1,0,1)
        _SecTexBrightness ("Secondary Texture Brightness", Range(0, 1.0)) = 0.5
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

            // Properties connection variables
            // -> to declare a connection variable we only need to declare a variable with the same name as the property declared and a coherent type to handle the value
            sampler2D _SecTex;
            float4 _SecTex_ST; // When declaring a texture we can also get its scale and translation information by using the suffix _ST after the property name
            float4 _MultColor;
            float1 _SecTexBrightness;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }


            // We use connection variable in the fragment shader to modify the textures 
            fixed4 frag (v2f i) : SV_Target
            {
                // sample main and secondary texture
                fixed4 mainTex = tex2D(_MainTex, i.uv);
                fixed4 secTex = tex2D(_SecTex, i.uv);

                // Multiply main texture color
                mainTex *= _MultColor; 

                // Process secondary texture brightness 
                secTex *= _SecTexBrightness; 

                // Add secondary texture on main texture
                fixed4 col = mainTex + secTex;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                // Return result
                return col;
            }
            ENDCG
        }
    }
}
