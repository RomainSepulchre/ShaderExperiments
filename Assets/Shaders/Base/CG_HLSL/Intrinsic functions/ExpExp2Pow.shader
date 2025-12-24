// Shader that use Exp(), Exp2() and Pow() intrinsic function to show how it works

// Intrinsic functions are CG/HLSL functions that does mathematical operations and help you to produce some effects. Like the word
// intrinsic suggest they are available without any include both in CG and HLSL 

// See https://developer.download.nvidia.com/CgTutorial/cg_tutorial_appendix_e.html
// See https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-intrinsic-functions

// Exp, Exp2 and Pow

// -> Exp(), Exp2() and Pow() are functions that use exponents to return new a value
//      - Exp(n): exponential function, n is used as an exponent of 2.7182828182846f (2.7182828182846f ^ n)
//      - Exp2(n): exponential function, n is used as an exponent of 2 (2 ^ n)
//      - Pow(x, n): n power of x (x ^ n) 
//      - See https://en.wikipedia.org/wiki/Exponential_function

// -> Exp(), Exp2() and Pow() are generally used to calculate noise gamma increase in the output color and repetition patterns.

// -> In this shader we use Sin() and Cos() to rotate the vertices of an object
//      - vertex has 3d coordinates (X,Y,Z) that we can transform with a rotation matrix to simulate the illusion of a rotation
//      - To rotate a vertex in 2D we sin() y axis to have a wave motion from top to bottom and we cos() x axis to have a
//        wave motion from left to right. The combination of both reproduce a circular motion.

Shader "LearnShader/BIRP_Unlit/CG_HLSL/Intrinsic Functions/Exp Exp2 Pow"
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

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                
                col *= fixed4(exp2(i.uv.x), exp2(i.uv.y), 0, 1);
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
