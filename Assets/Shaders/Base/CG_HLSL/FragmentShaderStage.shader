// Shader with annotation on CG/HLSL Fragment shader stage

Shader "LearnShader/BIRP_Unlit/CG_HLSL/FragmentShaderStage"
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

            // Fragment Shader Stage

            // -> Fragment refers to a pixel on the screen, an individual fragment or a group that covers an object area. The Fragment shader stage 
            //     process every pixels on the computer screen that belong to an object that use the shader.

            // fixed4 frag (v2f i) : SV_Target
            // -> The frag() function return a four dimensional value (here a fixed4) that correspond to the color of a pixel we need to draw.
            // -> v2f argument: the argument passed is the v2f object returned by the vert() function. It allows to use the vertex information 
            //    we processed in vert() inside frag().
            // -> SV_Target semantic: unlike vert(), frag() use a semantic called SV_Target (for System Value Target) which correspond to the 
            //    output value stored in the Render Target. Using this semantic allows frag() to update this value stored in the Render Target. 

            // Note: here the type returned by frag() is a fixed4 because we use CG code but if we want to use the shader with a scriptable render
            // pipeline we need to replace the fixed4 type by half4 or float4 since fixed value are not compatible with HLSL.

            fixed4 frag (v2f i) : SV_Target
            {
                // By default, we use tex2D() to sample the texture at a specific uv coordinate and find the color we need to use for the pixel. This
                // color value is stored in a fixed4 variable called col for color.
                fixed4 col = tex2D(_MainTex, i.uv);

                // We apply the fog on the color value we sampled on the texture
                UNITY_APPLY_FOG(i.fogCoord, col);

                // Finally, we return the color value we sampled. Thanks to the SV_Target semantic we specified, the returned color value is saved
                // in the Render Target.
                return col;
            }
            ENDCG
        }
    }
}
