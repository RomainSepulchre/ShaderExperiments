// Shader with comment to better understand the SubShader section
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-SubShader-object.html
// See https://docs.unity3d.com/6000.3/Documentation/Manual/SL-Blend.html

Shader "LearnShader/BIRP_Unlit/SubShader/Blend"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        // Enum property set with the type of the enum BlendMode to automatically use this enum values  
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Factor", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Factor", Float) = 1
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" } // Tags have been modified to mark the object as transparent

        // Blend
        
        // -> See https://docs.unity3d.com/6000.3/Documentation/Manual/SL-Blend.html
        // -> Blending is the process of mixing 2 pixels into one. It happens at the end of the render pipeline at a stage called Merging
        //    where the color of the pixel is merged with the frame buffer. Merging is also where the Stencil-Buffer, Z-Buffer and Color blending
        //    are executed.
        // -> Blend is an optionnal command that is mainly used to work with transparent objects. The effect of the parameter is similar to the
        //    bleding modes in Photoshop.
        // -> Like the tags, Blend can be declared in the Subshader or in the Pass.

        // -> The syntax to declare a Blend is : Blend sourceFactor DestinationFactor
        //      - source = pixel RGB Color output from fragment shader, destination = RGB Color written in the destination frame buffer (also known as RenderTarget).
        //      - when blending is enabled both colors are mixed to get a new color that override the values from the destination
        //      - when blending options are not enabled the values from the source override the values from the destination
        //      - SourceFactor and DestinationFactor are 3D vectors that modifies the colors to achieve interesting effect

        // -> Factors:
        //      - Off = disable blending options
        //      - One = (1,1,1)
        //      - Zero = (0,0,0)
        //      - SrcColor = RGB value of the source
        //      - SrcAlpha = Alpha value of the source
        //      - OneMinusSrcColor = 1 - RGB value of the source (1 - R, 1 - G, 1 - B)
        //      - OneMinusSrcAlpha = 1 - Alpha value of the source (1 - A, 1 - A, 1 - A)
        //      - DstColor = RGB value of the destination
        //      - DstAlpha = Alpha value of the destination
        //      - OneMinusDstColor = 1 - RGB value of the destination (1 - R, 1 - G, 1 - B)
        //      - OneMinusDstAlpha = 1 - Alpha value of the destination (1 - A, 1 - A, 1 - A)

        // -> Common blending types:
        //      - Blend SrcAlpha OneMinusSrcAlpha = Common transparent blending
        //      - Blend One One = Additive blending color
        //      - Blend OneMinusDstColor One = Mild additive blending color
        //      - Blend DstColor Zero = Multiplicative blending color
        //      - Blend DstColor SrcColor = Multiplicative blending x2
        //      - Blend SrcColor One = Blending overlay
        //      - Blend OneMinusSrcColor One = Soft light blending
        //      - Blend Zero OneMinusSrcColor = Negative color blending

        // Note: Alpha channel blending is done the same way as the RGB blending but in an independant process since it's not frequently used. This
        // also allows to optimize the writing in the Render Target.
        // Note: Blend can 

        Blend [_SrcBlend] [_DstBlend] // Use enum properties to set the blend mode in the inspector
        
        // Example: Common transparent blending
        //Blend SrcAlpha OneMinusSrcAlpha

        // Example: Disable the blend
        // Blend Off

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
