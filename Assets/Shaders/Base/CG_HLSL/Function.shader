// Shader with annotation on CG/HLSL Function

Shader "LearnShader/BIRP_Unlit/CG_HLSL/Function"
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
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
#pragma exclude_renderers d3d11
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

            // Function

            // -> Like in c#, in CG/HLSL it's also possible to declare void functions or functions that returns a value.
            // -> declare function before using them because code is processed from top to bottom

            // -> Depending on the type of function we have use declarations to determine if a value correspond to an input (in), an output (out),
            //    a global variable (uniform) or a constant (const).

            // VOID FUNCTIONS

            // Example:
            void functionName_precision (declaration type arg)
            {
                float value = 0;
                arg = value;
            }

            //
            void FakeLight_float (in float3 Normal, out float3 Out)
            {
                float[n] operation = Normal;
                Out = operation;
            }

            // -> In void function it is mandatory to precise the precision of the function after its name otherwise the function won't compile
            // EX:
            // void FakeLight_float (in float3 Normal, out float3 Out)
            // void FakeLight_half (in float3 Normal, out float3 Out)

            // RETURN FUNCTIONS

            // -> In return function precision and argument declaration is not needed.
            
            float3 FakeLight (float3 Normal)
            {
                float[n] operation = Normal;
                return operation;
            }

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
