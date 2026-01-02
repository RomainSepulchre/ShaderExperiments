// Shader that shows how shadows maps works

// Shadow mapping
// -> Shadow mapping is a simple concept, we use the frustum of the light source to generate a map of the light and shadow areas. This means
//    that the shadow projection of a directional light will be orthographic while the shadow projection of a point light or spot light will
//    be rendered in perspective.
// -> To calculate that we compare if a pixel is visible from the light source, if it isn't then another object block the light and the pixel must
//    be a shadow.
// -> To have a fully functional shadow mapping we need two things:
//      - A shadow caster, the shadow area projected by an object
//      - A shadow map, the shadow cast on an object

// Shadow map
// -> A shadow map is a texture, this means it has UV coordinates and it is calculated in two stages:
//      1. the scene is rendered from the light source viewpoint and the depth information are extracted from the Z-Buffer to be saved in a texture.
//      2. the scene is drawn on the GPU from the camera viewpoint and we calculate the UV coordinates of the texture saved from 1. to generate and
//         apply shadows onto the object we are working with.


// If we translate this to shader, this means we need 2 pass:
// - one pass to cast shadows (Shadow caster)
// - one pass to receive shadows (Shadow map)

// In this shader the shadow caster pass is implemented and we add the code for the shadow map.

//(ComputeScreenPos)
// See https://discussions.unity.com/t/what-does-the-function-computescreenpos-in-unitycg-cginc-do/565450/10
// See https://europe1.discourse-cdn.com/unity/optimized/3X/1/0/10b90837995f81ec931dfe37f14f872b4e6b1c68_2_500x500.jpeg

Shader "LearnShader/Shadows/Shadow Map"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        [Toggle] _UseCustomNDCToUV ("Use custom NDC to UV function", float) = 0
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
        
        // Default color pass where we add the shadow map
        Pass
        {
            // Name of the pass
            Name "Shadow Map Texture"
            Tags{
                "RenderType"="Opaque"
                "LightMode"= "ForwardBase" // We need to set the LightMode to ForwardBase to let Unity know this pass is affected by lighting
            }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            #pragma shader_feature _USECUSTOMNDCTOUV_ON

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
                
                // Declare UV coordinates for the shadow map
                float4 shadowCoord : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            // Declare a sampler for the shadow map
            // -> Only exist within CGPROGRAM, must not be declared as a property and we don't have to pass a texture manually in the inspector
            // -> We will generate a projection that will work as a texture.
            // -> the projection process must be done in frag() because the projection must be calulated per-pixel.
            // ? Do we need to use "_ShadowMapTexture" as name ??? not clear 
            sampler2D _ShadowMapTexture;
            
            // How to generate projection ?
            
            // -> UNITY_MATRIX_P is a matrix that allows us to go from view-space to clip-space and defines the object vertex position in relation to camera fustrum.
            // -> This is what happens when we use UnityObjectToClipPos() to convert the vertex position to clip-space, except inside this function we go from object-space
            //    to world-space with unity_ObjectToWorld and then we go from world-space to clip-space with UNITY_MATRIX_VP.
            
            // -> Once in Clip-space we can use the coordinates to generate Normalized Device Coordinate or NDC which means they have a range between -1 and 1 that map the screen
            //      -1,1  ---  1,1
            //        |         |         
            //      -1,-1 --- 1,-1
            // -> To generate those NDC we need to use the clip pos coordinate and divide the X, Y and Z components by W component:
            //      - xNDC = clipPos.x / clipPos.w
            //      - yNDC = clipPos.y / clipPos.w
            //      - zNDC = clipPos.z / clipPos.w
            
            // To get the shadow map uv coordinates we need to remap these NDC value to UV coordinates [-1,1] => [0,1]
            // The calculation is simple: "UV coord = (NDC coord + 1) / 2" (it is the opposite of what we do with normal maps to convert RGB value to XYZ coordinates
            
            // Optimized Function to go from Clip pos to UV Coordinates (Equivalent of ComputeScreenPos()): to have uv coordinate we must divide x and y by w of the result vector
            // -> What this function actually and ComputeScreenPos() actually does is to remap the range from [-w,w] to [0, w]
            // -> Direct3D and OpenGL UV coord are different (d3d = 0,0 is top left; ogl = 0,0 is bottom left) to take this into account unity provide an internal
            //    variable called _ProjectionParams that we can use to flip the value. 
            // -> _ProjectionParams component:
            //      - _ProjectionParams.x = 1 or -1 depending on platform for platform like Direct3D that use flipped transformation matrix
            //      - _ProjectionParams.y = Znear camera values
            //      - _ProjectionParams.z = Zfar camera values
            //      - _ProjectionParams.w = 1/Zfar
            // -> UNITY_HALF_TEXEL_OFFSET: macro enabled on platforms that need mapping displacement adjustement, we can combine it with _ScreenParams internal variable
            //    to take into consideration half-texel offset
            //      - _ScreenParams.x = width of the camera’s target texture in pixels
            //      - _ScreenParams.y = y is the height of the camera’s target texture in pixels
            //      - _ScreenParams.z = 1 + 1 / width
            //      - _ScreenParams.w = 1 + 1 / height
            float4 NDCToUV_Optimized(float4 clipPos)
            {
                float4 o = clipPos * 0.5;
            #if defined(UNITY_HALF_TEXEL_OFFSET)
                // use _ProjectionParams.x to flip V coordinate
                // multiply by _ScreenParams.zw to take into consideration half-texel offset
                o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w * _ScreenParams.zw;
            #else
                o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w; // use _ProjectionParams.x to flip V coordinate
            #endif
                o.zw = clipPos.zw;
                return o;
            }
            
            // Once we have a way to get shadow UV coordinates we can calcualte them in vert() and pass them to frag()
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                
                // Calulate Shadow uv coordinates using vertex position in clip-space
            #if _USECUSTOMNDCTOUV_ON
                o.shadowCoord = NDCToUV_Optimized(o.vertex); // Use our custom function
            #else
                o.shadowCoord = ComputeScreenPos(o.vertex); // Use Unity pre-defined function
            #endif
                
                return o;
            }
            
            //  In frag() we can use the shadow uv coordinates to sample _ShadowMapTexture and use the data sampled to project shadows onto the object
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // create shadow uv coord
                // -> Division by W must be done in fragment shader
                float2 uv_shadow = i.shadowCoord.xy / i.shadowCoord.w; // XY screenPos / W = UV coordinate
                
                // sample shadow map texture
                fixed shadow  = tex2D(_ShadowMapTexture, uv_shadow).a;
                
                // Another way to do this is to use tex2Dproj() and provide the full screenPos float4 as coordinate
                // -> https://discussions.unity.com/t/what-does-the-function-computescreenpos-in-unitycg-cginc-do/565450/7
                //fixed shadow  = tex2Dproj(_ShadowMapTexture, i.shadowCoord).a;
                
                
                // Apply shadow
                col.rgb *= shadow;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
