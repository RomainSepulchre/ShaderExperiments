// Shader for the object that act as a mask
// See https://docs.unity3d.com/6000.3/Documentation/Manual/SL-Stencil.html

Shader "LearnShader/Examples/Stencil/StencilExample_Mask"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // Queue is geometry(2000) minus a offset of one so 1999, this means this shader will be processed just before every other geometry objects
        Tags { "Queue"="Geometry-1" }  

        // We also want to disable Z-Write to prevent Unity to process the object based on it's camera-relative position in the scene. 
        Zwrite Off

        // Color Mask is set to 0 to prevent our mask to be rendered in the frame buffer
        ColorMask 0

        // Stencil command to make the object act as a mask
        Stencil
        {
            // StencilRef (value assigned to the stencil buffer)
            // -> We assign a value of 2 to the StencilRef
            Ref 2

            // Comp (comparison function used to define if the pixel must be drawn)
            // -> We use Always to make sure we take into account all the area covered by our objects when we set the stencil Buffer 
            //    to the Stencil Ref Value
            Comp Always
            
            // Pass (Operation the GPU to perform on the Stencil Buffer when a pixel pases the stencil and depth test)
            // -> We tell to replace the current value of the stencil buffer by the StencilRef value
            Pass Replace 
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
