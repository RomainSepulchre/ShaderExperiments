// Shader to write notes on standard surface shader Input and Output

// Just like in a Vertex-Fragment shader, the standard surface shader has two struct functions: Input and SurfaceOutputShader

// SurfaceOuputShader

// -> https://docs.unity3d.com/6000.2/Documentation/Manual/surface-shaders-language-reference-input-structure.html
// -> https://docs.unity3d.com/Manual/SL-SurfaceShaders-output.html
// -> See https://docs.unity3d.com/Manual/SL-SurfaceShaders.html

Shader "LearnShader/Lighting/Standard Surface/Input Output"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        
        [Header(Replace properties by custom value in surf function)]
        [Toggle] _ReplaceOutput ("Replace Output value", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows
        
        #pragma shader_feature _REPLACEOUTPUT_ON

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        
        // Input

        // -> Input is different from appdata. In appdata we can define our object semantics as an input while in Input we can determine
        //    our shader predefined functions for lighting calculation. This means in input we don't have to bind our variable to a semantic,
        //    however we need to use specific variable name that refers to a spefic input structure.
        // -> List of these references: https://docs.unity3d.com/6000.2/Documentation/Manual/surface-shaders-language-reference-input-structure.html
        struct Input
        {
            float2 uv_MainTex; // TEXCOORD0
            float3 viewDir; // View direction in world-space
            float4 Color : COLOR; // Vertex color, this an exception where a semantic is needed
            float3 worldPos; // vertex position in world-space
            float3 worldNormal; // normal in world-space
        };
        // viewDir, worldPos and worldNormal correspond to the same value we calculated manually when working on vertex-fragment shader lighting:
        //  - viewDir = normalize(_WorldSpaceCameraPos - i.vertex_world);
        //  - worldPos = mul(unity_ObjectToWorld, v.vertex);
        //  - worldNormal = normalize(mul(unity_ObjectToWorld, flaot4(v.normal, 0))).xyz;

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)
        
        
        // SurfaceOutputStandard
        
        // -> this type means the color output will be determined by the standard lighting model. It represent all the parameters that will used
        //    how our object surface will be rendered and how light will interact with it.
        // -> For example if I assign o.Albedo = fixed3(1,1,1); the base color of the object will be white instead of sampling the texture color. 
        // -> SurfaceOutputStandard variables are:
        //      struct SurfaceOutputStandard
        //      {
        //          fixed3 Albedo;
        //          fixed3 Normal;
        //          half3 Emission;
        //          half Metallic;
        //          half Smoothness;
        //          half Occlusion;
        //          fixed Alpha;
        //      };
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
        // Replace normal output by custom values to show how output values affect object rendering
        #if _REPLACEOUTPUT_ON
            // Albedo: Use input value to define a color based on world normal and view direction
            o.Albedo = IN.worldNormal * IN.viewDir; 
            
            // Metallic and smoothness: use custom value instead of slider variables
            o.Metallic = 1;
            o.Smoothness = 1;
            o.Alpha = 1;
            
        // Use normal output defined by material properties
        #else
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;

            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        #endif
        }
        ENDCG
    }
    FallBack "Diffuse"
}
