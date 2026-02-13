Shader "Hidden/Noise"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            
            float whiteNoise(float2 pos)
            {
                // Simple Gradient
                //return pos.x;
                
                // Star gradiant
                //return frac(pos.x * pos.y * 1000.0123);
                
                // Generic noise
                float random =  dot(pos, float2(12.,78.));
                random = sin(random);
                random = random * 43758.5453;
                random = frac(random);
                return random;
            }
            
            float valueNoise(float2 pos)
            {
                float2 gridUv = frac(pos);
                float2 gridId = floor(pos);
                
                gridUv = smoothstep(0.0, 1.0, gridUv);
                
                float botLeft = whiteNoise(gridId);
                float botRight = whiteNoise(gridId + float2(1.0, 0.0));
                float b = lerp(botLeft, botRight, gridUv.x);
                
                float topLeft = whiteNoise(gridId + float2(0.0, 1.0));
                float topRight = whiteNoise(gridId + float2(1.0, 1.0));
                float t = lerp(topLeft, topRight, gridUv.x);
                
                float noise = lerp(b, t, gridUv.y);
                
                return noise;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //fixed4 col = tex2D(_MainTex, i.uv) * fixed4(i.uv, 1, 1);
                //fixed4 col = fixed4(i.uv, 0, 1);
                
                // 1 - Base noise
                float2 uv = i.uv;
                float4 color;
                float noise = whiteNoise(uv);
                
                // 2.1 - Grid overlay
                //uv *= 2.0; // 2 by 2 grid
                uv *= 4.0; // 4 by 4 grid
                //uv *= 8.0; // 8 by 8 grid
                float2 gridUv = frac(uv);
                //color = float4(gridUv * noise, 0, 1);
                
                // 2.2 - Setup grid ID
                float2 gridId = floor(uv);
                //color = float4(gridId * noise, 0, 1) * 0.25;
                
                // 4 - Smooth
                gridUv = smoothstep(0.0, 1.0, gridUv);
                         
                // 3.1 - Lerp between bottom coords
                float botLeft = whiteNoise(gridId);
                float botRight = whiteNoise(gridId + float2(1.0, 0.0));
                float b = lerp(botLeft, botRight, gridUv.x);
                //color = b;
                
                // 3.2 - Lerp between top coords
                float topLeft = whiteNoise(gridId + float2(0.0, 1.0));
                float topRight = whiteNoise(gridId + float2(1.0, 1.0));
                float t = lerp(topLeft, topRight, gridUv.x);
                //color = t;
                
                // 3.3 Lerp between top and bottom
                float vNoise = lerp(b, t, gridUv.y);
                //color = valueNoise;
                
                // 5 - Noise layers (or Octaves) of value noise
                uv += _Time.y/10;
                float vn = valueNoise(uv * 4.0) * 1.0; // Every new octave the multiplication value are *2 and /2
                vn += valueNoise(uv * 8.0) * 0.5; 
                vn += valueNoise(uv * 16.0) * 0.25;
                vn += valueNoise(uv * 32.0) * 0.125;
                vn += valueNoise(uv * 64.0) * 0.0625;
                vn /= 2.0;
                color = fixed4(vn.xxx, 1.0);
                
                return color;
            }
            ENDHLSL
        }
    }
}
