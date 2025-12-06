// Shader that use the Toggle material property drawer to show how it works
// -
// Material property drawer allow to generate custom property in the material inspector.
// They are used like an attribute in C#: declared before a property definition inside [].
// Ex: Toggle, Enum, KeywordEnum, PowerSlider, IntRange, Space, Header
// See https://docs.unity3d.com/6000.2/Documentation/ScriptReference/MaterialPropertyDrawer.html
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-PragmaDirectives.html

Shader "LearnShader/MaterialPropertyDrawer/BIRP_Unlit_MDP_Toggle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,0,0,1)

        // Toggle property
        // -> shader doesn't support boolean but we can use a 0/1 value as a boolean (0=false, 1=true)
        // -> ! When using this, we need to use "#pragma shader_feature" inside CGPROGRAM to generate different status according to its state (see below) 
        [Toggle] _EnableTexture ("Enable Texture", Float) = 0 // Default value must be 0 or 1 as int
        // Example: [ToogleOff]
        [ToggleOff] _ToggleOffExample ("Off = Multiply texture with color (Toggle Off Example)", Float) = 0
        // Example: define custom shader keyword to identify our toggle constant
        [Toggle(TOGGLE_CUSTOM_KEYWORD)] _ToggleWithCustomKeyword ("Invert color (Toggle with custom keywork)", Float) = 0
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

            // Toogle: use "#pragma shader_feature" to declare a keyword for our toggle condition and use it in frag()
            // -> name must be the same as the property but in capital letters because shader variants are constants
            // -> we also add a suffix _ON to the condition is fullfilled when the property is enabled in the inspector
            //      -> when we need to invert the condition and use _OFF,  we need to use attribute [ToggleOff]
            // Note: "#pragma shader feature" cannot compile multiple variants of a shader for an application this means it's not possible to change the value
            //      of the toogle in a build at execution time. To do that we need to usea keyword enum drawer with "#pragma multi_compile".
            # pragma shader_feature _ENABLETEXTURE_ON
            // Example: [ToggleOff] / _OFF
            # pragma shader_feature _TOGGLEOFFEXAMPLE_OFF
            // Example: custom shader keyword (we use the keyword to get the value instead of the property name in capital and _ON is not needed)
            # pragma shader_feature TOGGLE_CUSTOM_KEYWORD

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
            float4 _Color;

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
                fixed4 col = fixed4(0,0,0,0);

                // Toggle - Custom keyword (Invert Color)
            #if TOGGLE_CUSTOM_KEYWORD
                float4 newColor = float4(1-_Color.r, 1-_Color.g ,1-_Color.b, 1);
                _Color = newColor;
            #endif

                // sample the texture
                fixed4 tex = tex2D(_MainTex, i.uv);

                // Toggle Off - Multiply texture by color when toggle is off
            # if _TOGGLEOFFEXAMPLE_OFF
                tex *= _Color;
            #endif

                // Toggle - Enable Texture
            #if _ENABLETEXTURE_ON
                col = tex; 
            #else
                col = _Color;
            #endif

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
