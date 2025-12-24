// Shader that use Sin() and Cos intrinsic function to show how it works

// Intrinsic functions are CG/HLSL functions that does mathematical operations and help you to produce some effects. Like the word
// intrinsic suggest they are available without any include both in CG and HLSL 

// See https://developer.download.nvidia.com/CgTutorial/cg_tutorial_appendix_e.html
// See https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-intrinsic-functions

// Sin and Cos

// -> Sin() and Cos() are trigonometry functions that return the sine or the cosine of an angle
//      - Sin() = sine (ratio between opposite keg and hypotenuse)
//      - Cosine() = cosine (ratio between adjacent keg and hypotenuse)
//      - See https://en.wikipedia.org/wiki/Sine_and_cosine#/media/File:Sine_cosine_one_period.svg

// -> Sin() and Cos() are very useful functions in computer graphics, you can use them to generate geometric figures and matrix
//    transformations.

// -> In this shader we use Sin() and Cos() to rotate the vertices of an object
//      - vertex has 3d coordinates (X,Y,Z) that we can transform with a rotation matrix to simulate the illusion of a rotation
//      - To rotate a vertex in 2D we sin() y axis to have a wave motion from top to bottom and we cos() x axis to have a
//        wave motion from left to right. The combination of both reproduce a circular motion.

Shader "LearnShader/CG_HLSL/Intrinsic Functions/Sin Cos (BIRP_Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // Speed of the rotation property
        _Speed ("Rotation Speed", Range(0, 10)) = 1
        
        // Keyword enum to select rotation axis
        [KeywordEnum(X,Y,Z)] _RotationAxis ("Rotation Axis", float) = 1
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
            #pragma multi_compile_fog // make fog work
            
            #pragma multi_compile _ROTATIONAXIS_X _ROTATIONAXIS_Y _ROTATIONAXIS_Z

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
            
            float _Speed;
            
        
            float3 RotateVertex(float3 vertex)
            {
                // Calculate sin and cos using _Time property to animate the rotation
                // -> _Time is a built-in property that give access to the time since the level load
                //      - _Time.x = t/20
                //      - _Time.y = t
                //      - _Time.z = t*2
                //      - _Time.w = t*3
                // -> https://docs.unity3d.com/6000.3/Documentation/Manual/SL-UnityShaderVariables.html
                float c = cos(_Time.y * _Speed);
                float s = sin(_Time.y * _Speed);
                
            #if _ROTATIONAXIS_X
                // Build a rotation matrix to rotate around X Axis
                float3x3 xRotMatrix = float3x3
                (
                    1, 0, 0,
                    0, c, -s,
                    0, s, c
                );
                
                // Apply rotation matrix
                return mul(xRotMatrix, vertex);
                
            #elif _ROTATIONAXIS_Y
                // Build a rotation matrix to rotate around Y Axis
                float3x3 yRotMatrix = float3x3
                (
                    c, 0, s,
                    0, 1, 0,
                    -s, 0, c
                );
                
                // Apply rotation matrix
                return mul(yRotMatrix, vertex);
                
            #elif _ROTATIONAXIS_Z
                // Build a rotation matrix to rotate around Z Axis
                float3x3 zRotMatrix = float3x3
                (
                    c, -s, 0,
                    s, c, 0,
                    0, 0, 1
                );
                
                // Apply rotation matrix
                return mul(zRotMatrix, vertex);
            #endif
            }

            v2f vert (appdata v)
            {
                v2f o;
                
                // Rotate the vertex and use rotated vertex to calculate clip pos
                float3 rotVertex = RotateVertex(v.vertex);
                o.vertex = UnityObjectToClipPos(rotVertex);
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
