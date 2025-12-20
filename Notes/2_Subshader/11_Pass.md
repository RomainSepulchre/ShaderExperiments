# Pass Block

**Links:**

- https://docs.unity3d.com/6000.3/Documentation/Manual/SL-Pass.html

## Pass Block

A Pass literally refers to a Render Pass. Each pass renders one object at a time so if we have a shader with two passes, the object will be rendered twice in the GPU or to be more precise the object will generate 2 draw calls. This is the reason why we try to use as few passes as possible, every new Pass generate an additional graphic load that can be very significant when performed to a big amount of objects.

A SubShader can contains several pass to generate several layers of effect. A good example that might need several pass is a diamond, we could have have pass for the background color of the diamond and a pass for the brighness of the diamond's surface.

### Example of shader using 2 pass

```c#
Shader
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
        ...

        // First Pass that simply applies a texture
        Pass
        {
            CGPROGRAM

            ...

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

        // Second Pass that applies a color based on the alpha channel of a texture
        Pass
        {   
            // Enable AlphaToMask to use texture alpha channel as a mask
            AlphaToMask On

            // Another solution (cleaner but more expensive): Override Tags and Blend in the pass to make the pass transparent
            //Tags { "Queue"="Transparent" "RenderType"="Transparent" }
            //Blend SrcAlpha OneMinusSrcAlpha          

            CGPROGRAM
            ...

            sampler2D _SecondTex;
            float4 _SecondTex_ST;
            float4 _SecondCol;

            v2f vert (appdata v)
            {
                ...
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
```
