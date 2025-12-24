// Shader that use Abs() intrinsic function to show how it works

// Intrinsic functions are CG/HLSL functions that does mathematical operations and help you to produce some effects. Like the word
// intrinsic suggest they are available without any include both in CG and HLSL 

// See https://developer.download.nvidia.com/CgTutorial/cg_tutorial_appendix_e.html
// See https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-intrinsic-functions

// Abs

// -> Abs return the input we provide as an absolute value, this means it return our input as a positive number.
// -> Ex:
//      - Abs(-3) = 3
//      - Abs(7) = 7
// -> Abs() is useful to recreate many effects such as kaleidoscope or generating a triplanar projection.
//      - Kaleidoscope: Get the absolute value of the uv coordinates and offset the texture to place center the kaleidoscope effect.
//      - Triplanar projection: Determine absolute value of the mesh normal to generate projections on both and negative axis (https://catlikecoding.com/unity/tutorials/advanced-rendering/triplanar-mapping/)

// -> In this shader we use Abs() to create a kaleidoscope effect  

Shader "LearnShader/CG_HLSL/Intrinsic Functions/Abs (BIRP_Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // Properties to set the texture offset
        _OffsetU ("U offset", Range(-3,3)) = -0.5
        _OffsetV ("V offset", Range(-3,3)) = -0.5
        
        // Property to rotate UV coordinates (0-360 because rotation degree)
        _UVRotation ("UV Rotation", Range(0,360)) = 0
        
        // Property to define the pivot of the uv rotation
        _URotationPivot ("U Rotation Pivot", Range(0,1)) = 0.5
        _VRotationPivot ("V Rotation Pivot", Range(0,1)) = 0.5
        
        // Debug Property
        _Debug ("Debug property", Range(-5,5)) = 0
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

            float _OffsetU;
            float _OffsetV;
            
            float _UVRotation;
            float _URotationPivot;
            float _VRotationPivot;
            float _Debug;
            
            // Function to rotate the uv in degree
            float2 RotateUVInDegrees(float2 uv, float2 center, float rotation)
            {
                rotation = rotation * (UNITY_PI/180); // Degree to radian conversion 
                uv -= center; // substract pivot center to uv coordiante to center the rotation around center float2 
                
                // Calculate sin and cos of rotation angle
                float s = sin(rotation); 
                float c = cos(rotation); 
                
                // Build a classic rotation matrix (https://en.wikipedia.org/wiki/Rotation_matrix)
                float2x2 rotMatrix = float2x2(c, -s, s, c);
                
                // Weird ? doesn't change anything => change then reset?
                // rotMatrix *= 0.5; // Lower scale to half (zoom in texture)
                // rotMatrix += 0.5; // Move matrice
                // rotMatrix = rotMatrix * 2 - 1; // ??? Reset to original value
                
                // Apply rotation matrix to uv coordinates
                // -> uv.xy = mul(rotMatrix, uv.xy); // invert matrix and uv coord => change rotation dir
                // -> using uv.yx instead of uv.xy in mul() change rotation direction
                uv.xy = mul(uv.xy, rotMatrix);
                
                // Add back the pivot center to bring back uv coordinate at their original position 
                uv += center;
                
                return uv;
            }
            
            // Function to rotate the uv in degree (based on Unity_Rotate_Degrees_float from shader graph Rotate node)
            // -> optimized because to apply rotation matrix we don't have to create a complete matrice
            float2 RotateUVInDegrees_SGraph(float2 uv, float2 center, float rotation)
            {
                rotation = rotation * (UNITY_PI/180.0f); // Degree to radian conversion 
                uv -= center; // substract pivot center to uv coordiante to center the rotation around center float2
                
                // Calculate sin and cos of rotation angle (sincos() calculate sin and cos simultaneously)
                float s, c;
                sincos(rotation, s, c);
                
                // Créer vecteur de rotation -> matrice de rotation sous forme compacte
                float3 rotVec = float3(-s, c, s);
                
                // Apply rotation matrix to uv coordinates
                // -> scalar product between uv and rotVec components => Optimized way to do mul(uv.xy, rotMatrix); because
                //    we don't have to create a complete matrice  
                float2 newUV;
                newUV.y = dot(uv, rotVec.xy);
                newUV.x = dot(uv, rotVec.yz);
                
                // Add back the pivot center to bring back uv coordinate at their original position
                return newUV + center;
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
                // Offset the x and y value of the uv and get it as an absolute value
                float u = abs(i.uv.x - _OffsetU);
                float v = abs(i.uv.y - _OffsetV);
                
                // Declare rotation pivot
                float2 pivot = float2(_URotationPivot, _VRotationPivot);
                
                // Rotate the uv
                //float2 rotUV = RotateUVInDegrees(float2(u, v), pivot, _UVRotation); // not optimized
                float2 rotUV = RotateUVInDegrees_SGraph(float2(u, v), pivot, _UVRotation); // optimized
                
                // Sample the texture by using rotated uv value as uv position
                fixed4 col = tex2D(_MainTex, rotUV);
                
                // Multiply texture by u and v absolute value as a color to better see the kaleidoscope effect
                //col *= fixed4(u, v, 0, 1);
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
