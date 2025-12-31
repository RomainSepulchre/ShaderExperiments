// Shader that shows how shadows caster pass works

// To have a fully functional shadow compatible shader we need 2 pass:
// - one pass to cast shadows (Shadow caster)
// - one pass to receive shadows (Shadow map)

// In this shader we write the shadow caster pass.

// -> In this example we include two version of the shadow caster pass:
//      - A simple version of the pass that use the vertex position and return 0 (black) as the frag() output but won't be compatible with
//        some of the lighting settings, we need to define more property for that.
//      - A version that use the macros included in UnityCG.cginc which makes all the lighting settings works out of the box

Shader "LearnShader/Shadows/Shadow Caster"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        [Toggle] _UseMacroShadow ("Use macro shadow", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        // Shadow caster pass
        Pass
        {
            // We declare a name for our shadow caster pass -> naming a pass is useful to use a functionality dynamically with the UsePass command
            // -> Name command is only used to give name and differentiate passes, it has no impact on shader rendering.
            Name "Shadow Caster"
            
            // We add the LightMode tag and set it to "ShadowCaster" because we need unity to recognize the pass as a shadow casting pass
            Tags {
                "RenderType"="Opaque"
                "LightMode"="ShadowCaster"
            }
            
            ZWrite On
        
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma shader_feature _USEMACROSHADOW_ON
            
            // Macro: All the shadow macro require "#pragma multi_compile_shadowcaster" to compile the shader shadow variants and to include UnityCG.cginc because
            // the macro are initialized in it
        #if _USEMACROSHADOW_ON
            #pragma multi_compile_shadowcaster
        #endif
            #include "UnityCG.cginc"
            
            struct appdata
            {
            #if _USEMACROSHADOW_ON
                float4 vertex : POSITION; // Get vertex position
                float3 normal : NORMAL; // When using macro we also need to add the normal in the input if we want TRANSFER_SHADOW_CASTER_NORMALOFFSET(o) to work
            #else
                float4 vertex : POSITION; // Since it is shadow caster pass we only need the vertices position as input and output
            #endif
            };

            struct v2f
            {
             #if _USEMACROSHADOW_ON
                 // contains several semantics for shadow calculation
                V2F_SHADOW_CASTER;
                // V2F_SHADOW_CASTER contains:
                // - vertex : SV_POSITION;
                // - normal_world : TEXCOORD1;
                // - tangent_world : TEXCOORD2;
                // - binormal_world : TEXCOORD3
            #else
                float4 vertex : SV_POSITION; // Pass vertex position to frag()
            #endif
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
            #if _USEMACROSHADOW_ON
                // Transform the vertex and normal input and pass them to v2f
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
            #else
                o.vertex = UnityObjectToClipPos(v.vertex);
            #endif
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
            #if _USEMACROSHADOW_ON
                // Handle color output for shadow projection
                SHADOW_CASTER_FRAGMENT(i)
            #else
                // Since shadow caster only correspond to a shadow projection we return 0 as frag() output
                return 0;
            #endif
            }
            ENDCG
        }

        // Default color pass
        // -> default pass included everytime we create a shader
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
