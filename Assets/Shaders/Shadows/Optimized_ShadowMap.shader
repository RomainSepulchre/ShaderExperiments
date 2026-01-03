// Shader that shows how to implement BIRP shadow mapping with optimized macro

Shader "LearnShader/Shadows/Optimized Shadow Map"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        
        // Shadow caster pass
        Pass
        {
            Name "Shadow Caster" // set the name of the pass
            
            Tags {
                "RenderType"="Opaque"
                "LightMode"="ShadowCaster" // set the LightMode tag to ShadowCaster
            }
            
            ZWrite On
        
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile_shadowcaster // compile shadow shader variants
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                // When using macro, vertex position and normal in the input if we want TRANSFER_SHADOW_CASTER_NORMALOFFSET(o) to work
                float4 vertex : POSITION;
                float3 normal : NORMAL; 
            };

            struct v2f
            {
                V2F_SHADOW_CASTER; // contains several semantics for shadow calculation
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o) // Transform the vertex and normal input and pass them to v2f
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i) // Handle color output for shadow projection
            }
            ENDCG
        }

        
        // Color Pass and shadow map implementation
        Pass
        {
            Name "Shadow Map texture" // Name
            Tags{ "LightMode"="ForwardBase" } // Set light mode to forward
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            // We need to add this directive to compile all lightmaps and shadow variants produced by directional light for the ForwardBase pass
            // -> "nolightmap nodirlightmap nodynlightmap novertexlight": the variable defined after pragma directive are optional parameter that let us add
            //    or remove features in the shadow behavior
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

            // 
            #include "UnityCG.cginc"
            
            // We need to include AutoLight.cginc to be able to use lights and shadows macro
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                // If we use macro to generate shadow map we need to use specific variable name in the input and output otherwise we will have compilation error
                // -> here "float2 uv : TEXCOORD0;" must be renamed to "texcoord"
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                
                SHADOW_COORDS(1) // => store shadow uv coord in TEXCOORD1 (no ; at the end)
                
                // If we use macro to generate shadow map we need to use specific variable name in the input and output otherwise we will have compilation error
                // -> here "float4 vertex : SV_POSITION;"must be renamed to "pos"
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                // replace standard variable name with new name
                o.pos = UnityObjectToClipPos(v.vertex); // new name = o.pos
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);// new name = v.texcoord
                UNITY_TRANSFER_FOG(o,o.vertex);
                
                // Transfer Shadow uv coordinates to fragment shader
                // -> this macro does the same as our custom NDCToUV() or as ComputeScreenPos()
                TRANSFER_SHADOW(o) // no ";" at the end of statement
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // Sample and project shadow from shadow map texture
                fixed shadow = SHADOW_ATTENUATION(i);
                
                // Apply shadow on the object
                col.rgb *= shadow;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
