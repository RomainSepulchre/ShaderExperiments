// Shader that shows how to implement URP shadow mapping with optimized macro

// See https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@14.0/manual/use-built-in-shader-methods-shadows.html

Shader "LearnShader/Shadows/URP_Shadow Mapping"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        [Toggle] _UseExampleGetLight ("Use example GetMainLight function", float) = 0
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalRenderPipeline" // Add URP tag
        }
        LOD 100
        
        // Shadow caster pass
        // -> Instead of writing completely the shadow caster pass we can use the UsePass command to get this pass from another shader. The URP Lit
        //    shader already has a pass called "ShadowCaster", with UsePass we only have to provide the shader path and pass name and we have a working
        //    shadow caster pass.
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

        // Default color pass : Include shadow map
        Pass
        {
            Tags { "LightMode"="UniversalForward"} // Set LightMode tag to Universal to tell unity this is an URP forward rendering pass
            
            // URP is only compatible with HLSL so we switch to HLSLPROGRAM
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // Pragma directive to allow the shader to access the main light shadow map
            #pragma multi_compile _ _MAIN_LIGHT_SHADOW
            
            #pragma multi_compile _ _USEEXAMPLEGETLIGHT_ON
            
            // Include HLSLSupport.cginc to improve CG type compatibility with HLSL (ex: fixed) 
            #include "HLSLSupport.cginc"
            
            // Include core HLSL functionalities (HLSL equivalent of UnityCG.cginc)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            // Include HLSL Lighting functionalities (it is necessary to have the shadow mapping macro)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 shadowCoord : TEXCOORD1; // Add a variable to store shadow coordiantes
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            // GetMainLight() (from Lighting.hlsl)
            // -> the examples below show the actual code behind GetMainLight()
            // -> this function return the main light data: light direction, attenuation, light color, etc
            // -> the function also has a third variation where we can include the shadowMask
            Light GetMainLightExample()
            {
                Light light;
                light.direction = _MainLightPosition;
                light.distanceAttenuation = unity_LightData.z;
                light.shadowAttenuation = 1.0;
                light.color = _MainLightColor.rgb;
                return light;
            }
            Light GetMainLightExample(float4 shadowCoord)
            {
                Light light = GetMainLightExample();
                light.shadowAttenuation = MainLightRealtimeShadow(shadowCoord);
                return light;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex); // HLSL equivalent of UnityObjectToClipPos()
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                // VertexPositionInputs
                // -> VertexPositionInputs is a type that directly store the position of a vertex in all the different coordiante space (world-space pos,
                //    view-space pos, homogeneous clip-space pos, homogeneous NDC pos)
                // -> See Core.hlsl (line 214) for its actual definition
                
                // GetVertexPositionInputs(float3 posObjSpace)
                // -> does all the necessary transformation to convert the position in object space to all the other coordinate space (world-space, view space,
                //    homogeneous clip-space, homogeneous NDC) and return an object of type VertexPositionInputs to that store them.
                // -> See ShaderVariablesFunctions.hlsl (line 8) for its definition and the code behind
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.shadowCoord = GetShadowCoord(vertexInput);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Get Main light data
            #if _USEEXAMPLEGETLIGHT_ON
                Light light = GetMainLightExample(i.shadowCoord);
            #else
                Light light = GetMainLight(i.shadowCoord);
            #endif
                
                // Get shadow from main light data
                float3 shadow = light.shadowAttenuation;
                
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // Apply shadow to the color
                col.rgb *= shadow;

                return col;
            }
            ENDHLSL
        }
    }
}
