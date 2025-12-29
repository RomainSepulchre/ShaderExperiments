// Shader that shows how diffuse reflections works

// Generally a surface can be defined by 2 types of reflection: Matte and Gloss

// Diffuse reflection obeys to Lambert's cosine law that defines Lambert shading. This rule makes an analogy between illumination
// and the surface of the object considering the light source direction and the surface normal.

// D = Dr * Dl * max(0, dot(n, l))
// Diffusion = Reflection color of light source * light intensity * max(0, dot(surface normal, light direction))

// -> See https://en.wikipedia.org/wiki/Diffuse_reflection
// -> https://www.geeksforgeeks.org/computer-graphics/diffuse-reflection-in-computer-graphics/

Shader "LearnShader/Lighting/Diffuse Reflection (BIRP Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // Property to control light intensity
        _LightInt ("Light Intensity", Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            // Since reflection is lighting pass we need to configure the render path
            Tags { "LightMode"="ForwardBase" }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL; // Get Normal
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal_world : TEXCOORD1; // Pass normal to fragment shader
            };
            
            // Connection variables
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _LightInt;
            
            // Internal variable
            float4 _LightColor0; // internal variable that refers to scene lighting color
            
            // Function that calculate diffuse reflection
            // -> normal and light direction must be in world-space
            float3 LambertShading(float3 ColorRefl, float lightInt, float3 normal, float3 lightDir)
            {
                // D = Dr * Dl * max(0, dot(n, l))
                return ColorRefl * lightInt * max(0, dot(normal, lightDir));
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normal_world = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0))).xyz; // Convert normal to world-space
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // Diffuse reflection parameter
                fixed3 colorRefl = _LightColor0.rgb; // _LightColor0 = internal variable that refers to scene lighting color (need initialization in CG uniform variables)
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz); // _WorldSpaceLightPos0 = internal variable that refers the direction of the directional light in world-space (initialized in UnityCG.cginc)
                float3 normal = i.normal_world;
                
                // Calculate diffuse reflections value
                half3 diffuse = LambertShading(colorRefl, _LightInt, normal, lightDir);
                
                // Include diffuse on texture
                col.rgb *= diffuse;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
