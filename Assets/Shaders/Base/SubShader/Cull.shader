// Shader with comment to better understand Cull command in the SubShader section
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-SubShader-object.html
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-Cull.html
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-VertexProgramInputs.html
// See https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-semantics

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

Shader "LearnShader/BIRP_Unlit/SubShader/Cull"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        // An enum property using UnityEngine.Rendering.CullMode as argument allows to dynamically choose the cull mode from the inspector
        [Enum(UnityEngine.Rendering.CullMode)] _CullFace ("Cull Face", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // Cull

        // -> The cull command allow you to control which face of a polygon will be removed when processing pixel depth. By default, the outer
        //    faces are rendered but the cull command can change that.

        // -> Cull modes:
        //      - Cull Off = Both faces are rendered
        //      - Cull Back = Back faces are rendered (outside of the object) - default
        //      - Cull Front = Front faces are rendered (inside of the object)

        Cull Off

        // Example: Use _Cull property to change cull mode from inspector
        // Cull [_Cull]

        // Note: when Cull is set to Off it possible to use the semantic SV_IsFrontFace in Frag() to paint different texture or color on both
        // faces (front and back) of the mesh
        // -> See Frag() below for an example

        AlphaToMask On // Enable alpha to mask to better see SV_IsFrontFace in scene

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

            // Example : Use SV_IsFrontFace semantic to paint on both face
            fixed4 frag (v2f i, bool face : SV_IsFrontFace) : SV_Target // Add a bool argument and assign it SV_IsFrontFace semantic
            {
                // sample the texture
                fixed4 tex = tex2D(_MainTex, i.uv);

                // Define a color for front and back faces
                fixed4 frontCol = fixed4(1,0,0,1);
                fixed4 backCol = fixed4(0,0,1,1);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, tex);

                // Use the bool to define change output
                return face ? tex * frontCol : tex * backCol;
            }
            ENDCG
        }
    }
}
