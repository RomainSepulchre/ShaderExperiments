// Shader with annotation on CG/HLSL Vertex shader stage

Shader "LearnShader/BIRP_Unlit/CG_HLSL/VertexShaderStage"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            // Vertex Shader Stage

            // -> The vertex shader stage is a programmable render pipleline stage where the objects vertices are transformed from a 3D space to
            //    a 2D projection on the screen. Its smallest unit of calculation is an independent vertex.
            // -> `vert()` correspond to the Vertex Shader Stage because of the directive `#pragma vertex vert`, without this pragma directive the
            //    GPU no longer knows that `vert()` is the Vertex Shader Stage.

            // v2f vert (appdata v)
            // -> When we look at vert() function signature we can see 2 things:
            //      - vert() return an object of type v2f that correspond to the v2f (vertex to fragment) struct defined previously
            //      - vert() argument is an object of type appdata that correspond to the appdata struct defined previously
            // -> This means vert() use the data from the appdata argument and output the data processed in v2f.

            v2f vert (appdata v)
            {
                // v2f is initialized with the letter o (which refers to all the v2f internal variables)
                v2f o;

                // UnityObjectToClipPos() is used on the vertex position data from appdata struct to transform it from object-space to clip-space
                // and the result is saved in o.vertex which correspond to v2f vertex position value.
                o.vertex = UnityObjectToClipPos(v.vertex);

                // TRANSFORM_TEX() use the object UV coordinates from appdata struct and a texture that must be positionned over these coordinates 
                // to define the tilling and the offset of the texture. The result is stored in o.uv which correspond to v2f uv coordinate value.
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                UNITY_TRANSFER_FOG(o,o.vertex);

                // Once all the data is processed we return the v2f object with the processed data.
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
