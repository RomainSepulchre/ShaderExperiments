// Shader that use Step() and SmoothStep() intrinsic function to show how they works

// Intrinsic functions are CG/HLSL functions that does mathematical operations and help you to produce some effects. Like the word
// intrinsic suggest they are available without any include both in CG and HLSL 

// See https://developer.download.nvidia.com/CgTutorial/cg_tutorial_appendix_e.html
// See https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-intrinsic-functions

// Step and SmoothStep

// -> Step() and SmoothStep() are similar functions that use an argument called edge to define the value that must be returned.
//      - Step(e, x): return one when x is greater or equal to e. otherwise return 0.
//      - SmoothStep(min, max, x): works like step but the value returned is interpolated linearly

// -> Step() and Smoothstep() can be used to create mask.

// -> In this shader we use step and smoothstep to create a mask.

Shader "LearnShader/CG_HLSL/Intrinsic Functions/Step Smoothstep (BIRP_Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // Step and Smoothstep properties
        [KeywordEnum(Step, SmoothStep)] _StepType ("Step Type", float) = 0
        _Edge ("Edge", Range(0,1)) = 0.5
        _Smooth ("Smooth", Range(0,1)) = 0.1
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
            #pragma multi_compile_fog
            
            // Keyword for step type selection
            #pragma multi_compile _STEPTYPE_STEP _STEPTYPE_SMOOTHSTEP

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
            
            float _Edge;
            float _Smooth;

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
                fixed4 col = tex2D(_MainTex, i.uv);
                
            #if _STEPTYPE_STEP
                fixed3 vStep = step(_Edge, i.uv.y);
            #elif _STEPTYPE_SMOOTHSTEP
                float smoothMin = i.uv.y - _Smooth; // Define the start position of the smooth 
                float smoothMax = i.uv.y + _Smooth; // Define the stop position of the smooth 
                fixed3 vStep = smoothstep(smoothMin, smoothMax, _Edge);
            #endif
                
                col.rgb *= vStep;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
