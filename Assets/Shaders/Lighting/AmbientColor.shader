// Shader that shows how to use the ambient color

// -> Ambient color is the hue of the illumination, this hue is defined by the reflection of multiple light sources across the environment.
//    In computer graphics we use a technique called **Global Illumination** which calculate indirect lighting to simulate the natural phenomenon
//    of light reflection.

// -> In Unity, if we open the lighting window (Window/Rendering/Lighting) and check the environment tab we can see two properties that are directly
//    used in the shader: source and ambient color.

// -> To get the value of the ambient color we can use UNITY_LIGHTMODEL_AMBIENT built-in variable (HDR value -> float for precision type)

Shader "LearnShader/Lighting/Ambient Color (BIRP Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // Property to control amount of ambient color
        [Header (Ambient Color Tint is defined in Ligthing_Environment )]_Ambient ("Ambient color intensity", Range(0, 1)) = 1
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
            
            // Connection variable for ambient color property
            float _Ambient;

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
                
                // Get ambient color and apply it on the texture
                // -> Get ambient color with UNITY_LIGHTMODEL_AMBIENT and modify its intensity with _Ambient property
                float3 ambientColor = UNITY_LIGHTMODEL_AMBIENT * _Ambient;
                col.rgb *= ambientColor;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
