// Shader that shows how specular reflections works

// The specular reflections add a specular brightness to a surface according to the position of its normal.

// S = Sa * Sp * max(0, dot(H, N)^2)
// Specular = Reflection color * specular intensity * max(0, dot(halfway, surface normal)^2)

// The big difference between diffuse and specular reflections is the H vector we use in the calculation. It refers to a half vector called halfway.
// We need H because if the specular reflection has the same angle as the light direction, we are only able to see the reflection when the camera is
// in the same direction. To solve this we calculate H to be an intermediate between the normal and the light direction, following the view direction. 

// H = L + E / magnitude(L + E)
// Halfway = Light direction + view direction / magnitude(Light direction + view direction)

// Since we always use normalized vectors we can even simplify the operation:
// H = normalize(L + E)
// Halfway = normalize(Light direction + view direction)

// -> UnityObjectToWorldNormal() is a UnityCG.cginc function that does the normal object to world-space conversion

Shader "LearnShader/Lighting/Specular Reflection (BIRP Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // Specular properties
        _SpecularTex ("Specular Texture", 2D) = "black" {} // black so no specular reflection added when there is no texture
        _SpecularInt ("Specular Intensity", Range(0,1)) = 1
        [IntRange] _SpecularPow ("Specular Power", Range(1, 128)) = 64
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
            "LightMode"="ForwardBase" // Since reflection is lighting pass we need to configure the render path
        }
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
                float3 normal : NORMAL; // Get normal
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal_world : TEXCOORD1; // Pass normal to frag() in worldSpace
                float3 vertex_world : TEXCOORD2; // vertex position in world space to calculate view direction
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            // Specular connections variables
            sampler2D _SpecularTex;
            float _SpecularInt;
            float _SpecularPow;
            
            // Internal variable
            float4 _LightColor0;
            
            // Function that calculate specular reflection
            // -> normal, view direction and light direction must be in world-space
            float3 SpecularShading(float3 colorRefl, float specularInt, float3 normal, float3 lightDir, float3 viewDir, float specularPow)
            {
                float3 h = normalize(lightDir + viewDir); // halfway
                
                return colorRefl * specularInt * pow(max(0, dot(normal, h)), specularPow);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normal_world =  UnityObjectToWorldNormal(v.normal); // UnityObjectToWorldNormal() is a UnityCG.cginc function that does the normal object to world-space conversion
                o.vertex_world = mul(unity_ObjectToWorld, v.vertex); // convert vertex position to world-space
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // Specular reflection parameters
                fixed3 colorRefl = _LightColor0;  // _LightColor0 = internal variable that refers to scene lighting color (need initialization in CG uniform variables)
                fixed3 specCol = tex2D(_SpecularTex, i.uv) * colorRefl;
                float3 normal = i.normal_world;
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz); // _WorldSpaceLightPos0 = internal variable that refers the direction of the directional light in world-space (initialized in UnityCG.cginc)
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.vertex_world); // Calculate view direction using camera position (_WorldSpaceCameraPos = internal variable that refers the camera position in world-space (initialized in UnityCG.cginc))
                
                // Calulate specular reflection
                half3 specular = SpecularShading(specCol, _SpecularInt, normal, lightDir, viewDir, _SpecularPow);
                
                // Add specularity on the texture
                col.rgb += specular;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
