// Commented unlit shader with basic concept of shaders
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-Properties.html

Shader "LearnShader/BIRP_Unlit_Bases" // Inspector path: path of the shader in Unity inspector interface 
{
    // Properties of the shader (textures, vectors, colors, etc)
    Properties
    {
        // Syntax to declare a property
        // PropertyName ("display name", typeOfProperty) = defaultValue
        //  - PropertyName = name of the property in the code (as a convention property name usually have a _ prefix)
        //  - "display name" = name of the property displayed in the inspector
        //  - typeOfProperty = color, vector, texture, float, int, etc
        // Note: property are not closed with an ; contrary to c# instructions
        _MainTex ("Texture", 2D) = "white" {}

        // Example of property
        _SecondaryColor ("Color", Color) = (1,1,1,1) // (R,G,B,A)
        _RangeExample ("Range Example", Range(0, 100)) = 50
        _FloatExample ("Float Example", Float) = 0.999
        _IntExample ("Int Example", Int) = 999
        _VectorExample ("Vector Example", Vector) = (0,0,0,1) //(X,Y,Z,W) when W=1 -> point in space, when W=0 -> direction
        _CubemapExample ("Cubemap Example", Cube) = "black" {}
        _3DTexExample ("3D Texture Example", 3D) = "white" {} 
    }

    // Subshader: field where we can declare commands and generate passes, a shader can contain several subshader
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM // define where we start to write code in CG
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata // ??? need more finfo
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f // ??? Vertex To Fragment -> Need more info
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            // Connections Variables to link property to variable in the code
            sampler2D _MainTex;
            float4 _MainTex_ST; // TextureProperty_ST : _ST -> Scale and Translation informations of the texture

            // Example: Declare a connection variable for Color property to be able to access its value in code
            float4 _SecondaryColor;

            // Vertex: Process Vertex position
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            // Note: 
            // Contrary to c# code, the GPU read the shader code linearly from top to bottom.
            // This means a function must be declared before being used.

            // Example: a function that return a float4 (0,0,0,0) used below when returning frag
            float4 GetFloat4Zero()
            {
                return float4(0,0,0,0);
            }

            // Fragment: Process Pixel Color
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                // Use GetFloat4Zero() function for example:
                return col * (GetFloat4Zero() + _SecondaryColor) ;
                //return col;
            }
            ENDCG // define where we end to write code in CG
        }
    }

    // We can also add a fallback field that define another shader to use if this one fails to compile
    // Fallback "AnotherShaderToUseAsFallback"
}
