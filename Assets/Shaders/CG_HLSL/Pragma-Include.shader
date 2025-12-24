// Shader with annotation on #pragma and #include

// See https://docs.unity3d.com/6000.4/Documentation/Manual/SL-PragmaDirectives.html
// See https://docs.unity3d.com/6000.2/Documentation/Manual/shader-include-directives.html
// See https://docs.unity3d.com/6000.3/Documentation/Manual/writing-shader-programs-pragma-directives.html

Shader "LearnShader/CG_HLSL/Pragma and Include (BIRP_Unlit)"
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

            // #pragma

            // -> #pragma is a preprocessor directive that provide machine or OS specific features while maintaining compatibility with C/C++
            //    language. It helps the program to recognize and compile some certain function. In CG/HLSL some pragma directives are needed
            //    to make sure the GPU correctly recognize the nature of certain functions.
            // -> For example "#pragma vertex vert" and "#pragma fragment frag" are needed to make sure the GPU compile the vert() and frag()
            //    functions as the vertex shader stage and fragment shader stage.

            // -> #pragma vertex vert: Allows the GPU to recognize and compile the vert() function as the vertex shader stage
            #pragma vertex vert

            // -> #pragma fragment frag: Allows the GPU to recognize and compile the frag() function as the fragment shader stage
            #pragma fragment frag

            // -> #pragma multi_compile_fog: this directive has 2 parts. "multi_compile" refers to a shader variant that generate variants
            // depending on functionnalities within the shader. "_fog" enable the fog functionnality from the lighting window on the object that
            // fade the object like it was disapearing in the fog when it is too far.
            #pragma multi_compile_fog


            // #include

            // -> #include let you use predefined variables and auxiliary functions in our shader. We specify a file where these variables and
            //    functions are defined and the shader will be able to compile them in the code.

            // -> For example "#include "UnityCG.cginc"" import a file located in unity install folder (Unity_install_path/Data/CGIncludes/UnityCG.cginc)
            //    If we open this file, we see that variables and functions are declared in it. When we include the file in the shader with #include all
            //    of these functions become available and compilable in our shader code.
            // -> Here is some example of functions declared in UnityCG.cginc that are used in the default unlit shader:
            //      - UNITY_FOG_COORDS(T)
            //      - UnityObjectToClipPos(V)
            //      - TRANSFORM_TEX(T, S)
            //      - UNITY_TRANSFER_FOG(O, C)
            //      - UNITY_APPLY_FOG(I, O)
            // -> Another example of variable included in UnityCG.cginc is UNITY_PI that allows use to use the value of Pi.
            #include "UnityCG.cginc"

            // Note: It's possible to create our own .cginc file to declare custom variables and functions. We just need to create a new file, declare
            // our variables/functions, save the file with the extension ".cginc" and use #include to include the file in the code.
            #include "Assets/Shaders/CG_HLSL/CustomCG.cginc"           

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1) // #include UnityCG.cginc: UNITY_FOG_COORDS() declared in UnityCG.cginc, only compile if UnityCG.cginc is included
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;


            // vert() is recognized and compiled as the vertex shader stage because of "#pragma vertex vert" directive
            v2f vert (appdata v)
            {
                v2f o;
                // #include UnityCG.cginc: UnityObjectToClipPos() is declared in UnityCG.cginc, only compile if UnityCG.cginc is included
                o.vertex = UnityObjectToClipPos(v.vertex); 

                // #include UnityCG.cginc: TRANSFORM_TEX() is declared in UnityCG.cginc, only compile if UnityCG.cginc is included
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // #include UnityCG.cginc: UNITY_TRANSFER_FOG() is declared in UnityCG.cginc, only compile if UnityCG.cginc is included
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            // frag() is recognized and compiled as the fragment shader stage because of "#pragma fragment frag" directive
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                // #include: use variables from custom Cginc file
                col = CUSTOMCG_RED + CUSTOMCG_GREEN;

                // #include UnityCG.cginc: UNITY_APPLY_FOG() is declared in UnityCG.cginc, only compile if UnityCG.cginc is included
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
