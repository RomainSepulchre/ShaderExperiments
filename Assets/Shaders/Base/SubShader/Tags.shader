// Shader with comment to better understand Tags command in the SubShader section
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-SubShader-object.html
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-SubShaderTags.html
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-ShaderReplacement.html

Shader "LearnShader/BIRP_Unlit/SubShader/Tags"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // Tags

        // -> Tags are labels that specify to the renderer how and when the shader must be processed. They can be used to know how a 
        //    shader will be rendered or how a group of shaders will behave graphically.
        // -> The syntax for adding a tag is: "TagName"="TagValue".
        // -> Tags can be declared either within a Subshader or inside a Pass section. Tags written in Subshader will affect every Pass included
        //    in it while Tags written in a Pass only affect this specific Pass.
        Tags
        {
            // Queue Tag

            // -> The function of the Queue Tag is to is to define the order in which the object must be processed by the GPU. By default this tag
            //    isn't show as a line of code because it is automatically compiled in the GPU.
            // -> Queue has a number value ranging from 0 to 5000, 0 is the farthest element from the camera and 5000 the closest. These values
            //    are organized in predifined groups:
            //      - Background (0-1499, default value=1000) - used for elements very far from camera such as a skybox.
            //      - Geometry (1500-2399, default value=2000) - used for opaque objects in the scene (default value in the Queue).
            //      - AlphaTest (2400-2699, default value=2450) - used for semi-transparent objects that are in front of an opaque object but behind a transparent object.
            //      - Transparent (2700-3599, default value=3000) - used for tranparent elements that must be in front of the others.
            //      - Overlay (3600-5000, default value=4000) - used for element rendered in front of the scene like UI ir images.
            // -> HDRP use the Render Queue differently by using two control methods: Material order and Renderer order.
            "Queue"="Geometry"

            // Render Type Tag
            
            // -> This tag allows to overwrite the behavior of a shader and add an effect on any material that matches a determined type. To
            //    do that we need at least 2 shaders a replacement one (color of effect to add at runtime) and a shader to be replaced
            //    (shader assigned on a material). This can be used to create some visual effect like an edge detection by example.
            //      => See Examples/Tags/RenderType and https://docs.unity3d.com/6000.2/Documentation/Manual/SL-ShaderReplacement.html
            // -> RenderType values are:
            //      - Opaque (default)
            //      - Transparent
            //      - TransparentCutout
            //      - Background
            //      - Overlay
            //      - TreeOpaque
            //      - TreeTransparentCutout
            //      - TreeBillboard
            //      - Grass
            //      - GrassBillboard
            "RenderType"="Opaque"
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
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
