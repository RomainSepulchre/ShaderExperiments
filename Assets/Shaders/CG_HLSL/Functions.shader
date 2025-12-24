// Shader with annotation on CG/HLSL Functions

// See https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-functions

Shader "LearnShader/CG_HLSL/Functions (BIRP_Unlit)"
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

            
            // Functions

            // -> Like in c#, in CG/HLSL it's also possible to declare functions to simplify the code. They are very similar to c# functions and
            //    can either be void or return a value.
            // -> Since CG/HLSL code runs from top to bottom, all functions must be declares before the place where they are called.

            // Functions with return value

            // -> The syntax of a function that return a value is exactly the same as a c# function.
            
            fixed3 UvToColor (float2 uv)
            {
                fixed3 uvAsCol = float3(uv.x, uv.y, 0);
                return uvAsCol;
            }

            // Void functions

            // -> Void functions however works differently, you need to add declarations to characterize the functions arguments and you need to
            //    specify the precision type at the end of its name.
            // -> Defining the precision type is mandatory with void functions otherwise the function won't compile. To define the precision you
            //    only need to add "_type" at the end of the function name (ex: void MyFunction_float()).
            //      -> ? Doesn't seems to be an issue with CG  
            // -> The declarations you add before the argument determine if a value correspond to an input (in), an output (out), a global variable
            //    (uniform) or a constant (const).
            
            // Example:
            // void functionName_precision (declaration type arg)
            // {
            //     arg = 0;
            // }

            void UvToColor_fixed (in float2 uv, out fixed3 uvCol)
            {
                fixed3 uvAsColGB = float3(0, uv.x, uv.y);
                uvCol = uvAsColGB;
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
                fixed4 tex = tex2D(_MainTex, i.uv);

                fixed4 col = fixed4(UvToColor(i.uv), 1);

                fixed3 secondCol;
                UvToColor_fixed(i.uv, secondCol);
                col += fixed4(secondCol, 1);

                col = tex * col;

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
