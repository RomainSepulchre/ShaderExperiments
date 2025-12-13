// Shader with comment to better understand Stencil command in the SubShader section
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-SubShader-object.html
// See https://docs.unity3d.com/6000.3/Documentation/Manual/SL-Stencil.html

Shader "LearnShader/BIRP_Unlit/SubShader/Stencil"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // Stencil

        // -> The stencil is way to define if a pixel need to be drawn or not in the fragment shader stage. The stencil buffer allows to store
        //    an int value of eight bits (0 to 255) for each pixel in the frame buffer. Before running the fragment shader, the GPU can run
        //    a Stencil Test: it compares the current value in the stencil buffer with a determined reference value to know if the pixel should
        //    be drawn or not. If the stencil test passes the GPU performs the following operations such as the Depth Test and if the stencil test
        //    fails the GPU skip the rest of the processing for this pixel.
        // -> This means that by using the stencil buffer as a mask we can tell the GPU which pixels to draw and which pixels to discard.

        // -> The function performed by the stencil test does this:

        // if(StencilRef & StencilReadMask [Comp] StencilBufferValue & StencilReadMask)
        // {
        //     // Draw pixel 
        // }
        // else
        // {
        //     // Discard pixel
        // }

        // -> StencilRef = Reference value passed to the stencil buffer. It works as an id that maps all the pixels found in the Stencil Buffer.
        //    This means if we set the StencilRef to 2 on a shader, the value of the Stencil Buffer for all the pixels covering the object area
        //    will be 2. 
        // -> StencilReadMask = A mask is automatically created for all the pixels that have a reference value. By default, the value of this
        //    mask is 255.
        // -> Comp = Comp is the comparison function we want to use to define if the pixel should be drawn or not.
        //    Here is the list of those functions:
        //      - Comp Never (1): always return false
        //      - Comp Less (2): < 
        //      - Comp Equal (3): ==
        //      - Comp LEqual (4): <=
        //      - Comp Greater (5): >
        //      - Comp NotEqual (6): !=
        //      - Comp GEqual (7): >=
        //      - Comp Always (8): always return true
        //      Note: Correspond to an int value in Rendering.CompareFunction enum value 

        Stencil
        {
            // StencilRef (value assigned to the stencil buffer)
            Ref 2 

            // Comp (comparison function used to define if the pixel must be drawn)
            Comp Always 

            // Pass = define the operation we want the GPU to perform on the Stencil Buffer when a pixel pases the stencil and depth test 
            //  - Keep (0): Keep current content of the stencil buffer
            //  - Zero (1): Write 0 into the stencil buffer
            //  - Replace (2): Write the refrence value into the buffer
            //  - IncrSat (3): Increment the value in the buffer, if the value is already at 255 it stays at 255
            //  - DecrSat (4): Decrement the value in the buffer, if the value is already at 0 it stays at 0
            //  - Invert (5): Negate all the bits of the current value in the buffer
            //  - IncrWrap (6): Increment the value in the buffer, if the value is already at 255 it wraps to 0
            //  - DecrWrap (7): DecrSat (4): Decrement the value in the buffer, if the value is already at 0 it wraps to 255
            //  Note: Correspond to an int value in Rendering.StencilOp enum value 
            Pass Replace
            
        }

        // Note: To use the Stencil Buffer we need at least 2 shaders: one shader for the mask and one for the object that must be masked.

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
