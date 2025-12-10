// Shader with comment to better understand ZWrite command in the SubShader section
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-SubShader-object.html
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-ZWrite.html

// Z-Buffer/Depth Buffer

// -> Every pixels have a color value but thay also have a depth value called Z-Buffer or Depth Buffer. The depth buffer store if an object
//    goes in front or behind another on the screen. The Z-Buffer measure the depth of pixel in term of distance from camera, a pixel closer
//    to the camera will have a lower Z-Buffer value and a pixel farther with have a higher Z-Buffer value.
// -> Z-Buffer allows to know if a pixel need to be updated or not, During rendering pixels with a lower z-buffer value will overwrite
//    the pixels with higher value.
// -> We can modify the Z-Buffer values to generate visual effect using the Cull, ZWrite and ZTest command. Like Tags this can be done
//    either in the subshader or in the pass to select at which level we want to use command.
//      -> For example, if we want to create a diamond shader we need two passes with different culling options:
//          - A first pass for the background color of the diamond
//          - A seocnd pass for the brightness of the diamond surface 

Shader "LearnShader/BIRP_Unlit/SubShader/ZWrite"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0,0,1,1)

        // ZWrite can be enable/disabled dynamically from the inspector with a Toggle property
        [Toggle] _ZWrite ("ZWrite", Float) = 0
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "RenderType"="Transparent" } // Queue and render type set to transparent
        Blend SrcAlpha OneMinusSrcAlpha // Use a transparency blend mode 

        // ZWrite

        // -> This command controls the writing of the surface pixels of an object to the Z-Buffer. This means it allows us to ignore or respect
        //    the depth distance between the camera and an object.
        // -> When working with transparent objects we usually want to disable Z-Buffer to prevent Z-Fighting issue. Z-Fighting happens when
        //    several objects are at the same distance from camera, thay have an identical Z-Buffer value that prevent the GPU to know which
        //    object is on front)
        
        // -> ZWrite mode:
        //      - ZWrite Off = for transparency
        //      - ZWrite On = default value

        //ZWrite Off

        // Example: use _ZWrite property to change ZWrite value from the inspector
        ZWrite [_ZWrite]


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
            float4 _Color;

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
                fixed4 tex = tex2D(_MainTex, i.uv);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, tex);

                return tex * _Color;
            }
            ENDCG
        }
    }
}
