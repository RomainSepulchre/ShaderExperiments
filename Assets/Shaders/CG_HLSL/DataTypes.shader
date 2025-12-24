// Shader with annotation on CG/HLSL Data types

// See https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-data-types
// See https://developer.download.nvidia.com/cg/Cg_language.html

Shader "LearnShader/CG_HLSL/Data Types (BIRP_Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tex ("Texture", 2D) = "white" {}
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

            // CG/HLSL Data types

            // Data type precision

            // -> In shader to optimize calculation we can use type with a different level of precision:
            //      - Float: 32 bit high precision data type. Usually used when calculating world-space positions, UV coordinates or complex scalar
            //        calculation such as trigonometry or exponentiation.
            //      - Half: 16 bit medium precision data type. Usually used for the calculation of low magnitude vectors, directions, object-space
            //        positions and high dynamic range colors.
            //      - Fixed (only works with CG, not compatible with HLSL): 11 bit low precision data type. Usually used for simple operations like
            //        basic color storage.
            // -> Why not use only float ? It's possible in practice but since its a high precision data type the GPU will take a longer time to
            //    process the additionnal decimals. Using the correct data type allows to optimize the program and reduce the graphic load.

            // Scalar values: return a real number either an integer or decimal.

            float floatExample = 0;
            half halfExample = 1.234;
            fixed fixedExample = 3.1;

            // Vectors: return a value with more than one dimension
            // -> To declare a vector we specify the data type and the number of dimensions (ex: float3 = vector with 3 dimensions (X,Y,Z) storing
            //    float values)

            float2 floatXY = float2(0.5, 0.5);
            half3 halfXYZ = half3(0, 0, 0);
            fixed4 fixedXYZW = fixed4(1, 1, 1, 1);

            // Matrices: store values in rows and columns and usually have more than one dimension.
            // -> matrices are mainly used for shearing, rotation and changing vertex position.
            // -> To declare a matrice we specify the data type and the number of dimension multipled by itself (ex: float3x3 = matrice of 3 rows
            //    and 3 columns stroring float values)

            float3x3 float3by3Matrice = float3x3
            (
                1, 0, 0,
                0, 1, 0,
                0, 0, 1
            );

            half2x2 half2by2Matrice = half2x2
            (
                1, 0,
                0, 1
            );

            fixed4x4 fixed4by4Matrice = fixed4x4
            (
                1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 0
            );
            
            // Other data types

            // - Int: a signed integer stored on 32 bit
            int intExample = 1;
            // - Texture2D: Store a texture.
            texture2D texExample;
            // - SamplerState: store the sample of a texture
            SamplerState samplerStateExample;
            // - Sampler2D / SamplerCube: It store a both a texture ant its sample.
            sampler2D sampler2DExample;
            
            // See Texture2D, SamplerState and sampler2D example below...

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

            // Sampler2D - Using Sampler2D to get texture and sampler at one time
            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            // Texture2D and SamplerState - Get texture and sampler separately using Texture2D and SamplerState
            texture2D _Tex;
            SamplerState sampler_Tex;

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
                // Sampler2D - Sample the texture and its UV coordinate using tex2D()
                fixed4 col = tex2D(_MainTex, i.uv);

                // Texture2D and SamplerState - Sample the texture in UV coordinate 
                fixed4 tex = _Tex.Sample(sampler_Tex, i.uv);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
