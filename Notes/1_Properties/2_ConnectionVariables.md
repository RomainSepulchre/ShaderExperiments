# Connection variables

**Links:**

- https://docs.unity3d.com/6000.2/Documentation/Manual/SL-Properties.html

## Connection variables

When you want to use your properties in your shader code (CG/HLSL) you need to declare a connection variable. A connection variable is a global variable in your shader code that has the exact same name as your property and a coherent type to store the value of the property. Since the connection variable store the value of the property, you can use it the code where you need to do something with the property.

Since CG/HLSL code run from top to bottom, the connection variable or any global variable must be declared before the place where they are used in the code. Usually, connections variables are declared before `vert()`.

> Generally, in CG/HLSL a global variable is declared with the word `uniform`: `uniform float4 _Color`. Unity skip this because the declaration is included internally in the shader.

```c#
Shader "..."
{
    Properties
    {
        // Properties that need connection variables to be used in the CG or HLSL code
        _MainTex ("Texture", 2D) = "white" {}
        _SecTex ("Secondary Texture", 2D) = "white" {}
        _MultColor ("Color", Color) = (0,1,0,1)
        _SecTexBrightness ("Secondary Texture Brightness", Range(0, 1.0)) = 0.5
    }
    SubShader
    {
        ...

        Pass
        {
            CGPROGRAM

            // Pragma, includem, appdata and v2f struct
            ...

            // Connections variables
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _SecTex;
            float4 _SecTex_ST; // When declaring a texture we can also get its scale and translation information by using the suffix _ST after the property name
            float4 _MultColor;
            float1 _SecTexBrightness;

            v2f vert (appdata v)
            {
                ...
            }

            // We use connection variable in the fragment shader to modify the textures 
            fixed4 frag (v2f i) : SV_Target
            {
                // sample main and secondary texture
                fixed4 mainTex = tex2D(_MainTex, i.uv);
                fixed4 secTex = tex2D(_SecTex, i.uv);

                // Multiply main texture color
                mainTex *= _MultColor; 

                // Process secondary texture brightness 
                secTex *= _SecTexBrightness; 

                // Add secondary texture on main texture
                fixed4 col = mainTex + secTex;

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
```

> When declaring a texture connection variable we can also create another connection variable to get its scale and translation information by using the suffix _ST after the property name: `float4 _MainTex_ST;`

