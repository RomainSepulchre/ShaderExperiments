// Shader with comment to better understand the Pass section
// See https://docs.unity3d.com/6000.2/Documentation/Manual/SL-SubShader-object.html
// See https://docs.unity3d.com/6000.3/Documentation/Manual/SL-Pass.html

Shader "LearnShader/BIRP_Unlit/SubShader/Pass"
{
    Properties
    {
        
        [Header(First Pass)]
        _MainTex ("Texture", 2D) = "white" {} // Texture applied in the first pass

        [Header(Second Pass)]
        _SecondTex ("Second Pass Texture (With Alpha)", 2D) = "white" {} // Texture used for it's alpha channel in the second pass
        _SecondCol ("Second Pass Color", Color) = (1,0,0,1) // Color applied on top of the texture alpha channel
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" } // Main render type is opaque
        LOD 100

        // Pass

        // -> A Pass literally refers to a Render Pass. Each pass renders one object at a time so if we have a shader with two passes, the object
        //    will be rendered twice in the GPU or to be more precise the object will generate 2 draw calls. This is the reason why we try to use
        //    as few passes as possible, every new Pass generate an additional graphic load that can be very significant when performed to a big
        //    amount of objects.  
        // -> A SubShader can contains several pass to generate several layers of effect. A good example that might need several pass is a
        //    diamond, we could have have pass for the background color of the diamond and a pass for the brighness of the diamond's surface.

        // Example: First Pass that simply applies a texture
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

        // Example: Second Pass that applies a color based on the alpha channel of a texture
        Pass
        {
            // Enable AlphaToMask to use texture alpha channel as a mask
            AlphaToMask On

            // Another solution (cleaner but more expensive): Override Tags and Blend in the pass to make the pass transparent
            //Tags { "Queue"="Transparent" "RenderType"="Transparent" }
            //Blend SrcAlpha OneMinusSrcAlpha          

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

            sampler2D _SecondTex;
            float4 _SecondTex_ST;
            float4 _SecondCol;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _SecondTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample second texture
                fixed4 texCol = tex2D(_SecondTex, i.uv);
                
                // Get Second Color
                fixed4 col = _SecondCol;

                // Multiply color by texture alpha channel to apply it depending on the alpha channel
                col *= texCol.a;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
