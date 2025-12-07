// Shader that use the Header and Space material property drawer to show how they works.
// Header and Space are similar to the attributes with the same name in c#, they're useful to organize the property in the inspector
// -
// Material property drawer allow to generate custom property in the material inspector.
// They are used like an attribute in C#: declared before a property definition inside [].
// Ex: Toggle, Enum, KeywordEnum, PowerSlider, IntRange, Space, Header
// See https://docs.unity3d.com/6000.2/Documentation/ScriptReference/MaterialPropertyDrawer.html
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-PragmaDirectives.html

Shader "LearnShader/MaterialPropertyDrawer/BIRP_Unlit_MPD_HeaderAndSpace"
{
    Properties
    {
        // Header Property
        // -> Add a header before the property with the title
        [Header(Textures)]
        _MainTex ("Main Texture", 2D) = "white" {}

        // Space property
        // -> Add space between two properties (here we add 10 points of space)
        [Space(10)]
        _SecTex ("Second Texture", 2D) = "white" {}
        // -> Another space example with 50 points of space
        [Space(50)]
        _ThirdcTex ("Third Texture", 2D) = "white" {}

        
        // Space


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
