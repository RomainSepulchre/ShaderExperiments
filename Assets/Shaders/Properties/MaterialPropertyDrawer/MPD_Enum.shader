// Shader that use the Enum material property drawer to show how it works
// -
// Material property drawer allow to generate custom property in the material inspector.
// They are used like an attribute in C#: declared before a property definition inside [].
// Ex: Toggle, Enum, KeywordEnum, PowerSlider, IntRange, Space, Header
// See https://docs.unity3d.com/6000.2/Documentation/ScriptReference/MaterialPropertyDrawer.html
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-Cull.html

Shader "LearnShader/BIRP_Unlit/MaterialPropertyDrawer/MPD_Enum"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        // Enum property
        // -> The difference between a KeywordEnum and an Enum is that Enum allows to define more than one value/id
        // -> The id/value set can be passsed to a command in the shader so they can be run dynamically from the inspector
        // -> When we define our Enum states we write the name of a state followed by a coma and the value of this state.
        // -> To add another state, we just need to add a new coma then the state and its value. (ex: State1, 0, State2, 1, State3, 2)
        [Enum(Off, 0, Front, 1, Back, 2)] _CullFace ("Cull Face", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        // Enum: instead of defining a value for the Cull command in the shader code, we use our enum to define it dynamically from the inspector
        // -> To use the property we need to write its name between [] (ex: Cull Front => Cull [_EnumValue])
        Cull [_CullFace]

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
