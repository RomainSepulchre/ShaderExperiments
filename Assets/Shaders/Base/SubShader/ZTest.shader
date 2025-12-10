// Shader with comment to better understand ZTest command in the SubShader section
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-SubShader-object.html
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-ZTest.html

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

Shader "LearnShader/BIRP_Unlit/SubShader/ZTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Alpha ("Alpha", Range(0, 1.0)) = 0.5

        // An enum property using UnityEngine.Rendering.CompareFunction as argument allows to dynamically choose the ZTest mode from the inspector
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest Mode", Float) = 1
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "RenderType"="Transparent" } // Queue and render type set to transparent
        Blend SrcAlpha OneMinusSrcAlpha // Use a transparency blend mode 

        // ZTest

        // -> ZTest command controls how the depth testing is performed. When setting ZTest mode, we define an operation we want to use to compare
        //     Z-Buffer values. It is generally used in shaders with several passss to generate different colors and depths.

        // -> ZTest modes:
        //      - Less = (<) Draws the objects in front. Objects at the same distance or behind are ignored.
        //      - Greater = (>) Draws the objects in behind. Objects at the same distance or in front are ignored.
        //      - LEqual = (<=) Draws the objects in front or at the same distance. Objects behind are ignored (Default mode).
        //      - GEqual = (>=) Draws the objects behind or at the same distance. Objects in front are ignored.
        //      - Equal = (==) Draws the objects at the same distance. Object in front or behind are ignored.
        //      - NotEqual = (!=) Draws objects that are not at the same distance. Objects at the same distance are ignored.
        //      - Always = Draws all pixels regardless of their Z-Buffer value.

        //ZTest Greater

        // Example: Use _Cull property to change cull mode from inspector
        ZTest [_ZTest]


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
            float _Alpha;

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
                tex.a = _Alpha;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, tex);

                return tex;
            }
            ENDCG
        }
    }
}
