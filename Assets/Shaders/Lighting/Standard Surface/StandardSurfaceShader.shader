// Shader to explore the structure of a standard shader

// By default the standard shader has Global lighting, diffusion, reflection and fresnel. They are already implemented internally.

// -> See https://docs.unity3d.com/Manual/SL-SurfaceShaders.html

Shader "LearnShader/Lighting/Standard Surface/Standard Surface Shader (BIRP Standard)"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        
        // No Pass{}
        // -> In a standard shader there is no Pass{} section, CGPROGRAM is written directly inside SubShader{}

        CGPROGRAM
        
        // Physically based Standard lighting model, and enable shadows on all light types
        // #Pragma surface surf
        // -> Just like "#pragma vertex vert" and "#pragment fragment frag" declare vert() and frag() as the vertex and fragment
        //    shader functions, "#pragma surface surf" declare surf() as the color output function.
        // -> Contrary to #pragma vertex and #pragment fragment, #pragma surface has additionnal parameter:
        //      - Standard: this first parameter is to define the lighting model
        //      - fullforwardshadows: The other parameters like "fullforwardshadows" are optionnal parameters       
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        // surf() function
        // -> surf() is the equivalent of to the object surface color output, "#pragma surface surf" declare it as the color
        //    output function (just like "#pragma vertex vert" and "#pragment fragment frag" declare vert() and frag() as the
        //    vertex and fragment shader functions)
        // -> surf() has 2 arguments: "input IN" and "inout SurfaceOutputStandard o" they refer to the shader input and output,
        //    their semantics is defined internally in the code
        
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
