// Shader that use the PowerSlider and IntRange material property drawer to show how they works.
// PowerSlider and IntRange are particulary useful when working with numerical ranges and precision.
// -
// Material property drawer allow to generate custom property in the material inspector.
// They are used like an attribute in C#: declared before a property definition inside [].
// Ex: Toggle, Enum, KeywordEnum, PowerSlider, IntRange, Space, Header
// See https://docs.unity3d.com/6000.2/Documentation/ScriptReference/MaterialPropertyDrawer.html

Shader "LearnShader/MaterialPropertyDrawer/BIRP_Unlit_MPD_PowerSliderAndIntRange"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        // PowerSlider property
        // -> PowerSlider generates a non-linear slider with curve control
        // -> The value provided for the power slider is the force of the response curve.
        //      -> For example with a 0 to 1 slider using a response curve of 3, 0.5 will be on the far right of the range instead of the middle of the range.
        //         This means, we will have way more precision when selecting a low value on the slider than when selecting a high value.  
        [PowerSlider(3)] _Brightness ("Brightness (Power Slider)", Range(0, 1)) = 0.5

        // IntRange property
        // -> IntRange adds a numerical range of integer values, Its a classic slider but it restrict the value in the range to int. 
        [IntRange] _IntRange ("Int Range", Range(0,255)) = 100
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

            // PowerSlider and IntRange
            // -> Like other properties to use them in the shader code we need to declare a connection variable that has the property name and a coherent value type.
            float _Brightness;
            int _IntRange;


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

                // PowerSlider and IntRange - Use PowerSlider value to darken the texture 
                col *= _Brightness;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
