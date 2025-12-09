// Shader that use the Keyword Enum material property drawer to show how it works
// -
// Material property drawer allow to generate custom property in the material inspector.
// They are used like an attribute in C#: declared before a property definition inside [].
// Ex: Toggle, Enum, KeywordEnum, PowerSlider, IntRange, Space, Header
// See https://docs.unity3d.com/6000.2/Documentation/ScriptReference/MaterialPropertyDrawer.html
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-PragmaDirectives.html

Shader "LearnShader/BIRP_Unlit/MaterialPropertyDrawer/MPD_KeywordEnum"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        // KeywordEnum property
        // -> where a toggle only allows for 2 state (true/false), a keyword enum allows to define up to 9 states and generate and dropdown selector in the inspector window
        // Like a standard C# enum, the value of the enum is represented by an int
        [KeywordEnum(Off, Black, Red, Green, Blue)] _TexColor ("Texture Color", Float) = 0
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

            // KeywordEnum: use #pragma shader_feature or #pragma multi_compile to declare our keywordEnum states and be able to use them in the CG code
            // -> When building "shader_feature" will only export the selected variant whereas "multi_compile" will export all variants found in the shader
            // -> This means "multi_compile" allows to change the keywordEnum value in a build at execution time while it's not possible with "shader_feature".
            // -> After pragma, we declare all our states by using the name of the property followed by _ and the name of the state all in capital: _PROPERTYNAME_STATUSNAME
            #pragma multi_compile _TEXCOLOR_OFF _TEXCOLOR_BLACK _TEXCOLOR_RED _TEXCOLOR_GREEN _TEXCOLOR_BLUE

            // Example: using "shader_feature" instead of "multi_compile"
            //#pragma shader_feature _TEXCOLOR_OFF _TEXCOLOR_BLACK _TEXCOLOR_RED _TEXCOLOR_GREEN _TEXCOLOR_BLUE

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

                // KeywordEnum - Multiply texture by a color depending on enum state
            #if _TEXCOLOR_OFF // = multiped by white
                // No need to do anything
            #elif _TEXCOLOR_BLACK
                col *= float4(0.1,0.1,0.1,1);
            #elif _TEXCOLOR_RED
                col *= float4(1,0,0,1);
            #elif _TEXCOLOR_GREEN
                col *= float4(0,1,0,1);
            #elif _TEXCOLOR_BLUE
                col *= float4(0,0,1,1);
            #endif

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
