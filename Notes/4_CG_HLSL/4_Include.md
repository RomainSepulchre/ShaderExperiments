# CG / HLSL Include

**Links:**

- https://docs.unity3d.com/6000.2/Documentation/Manual/shader-include-directives.html

## Include

`#include` let you use predefined variables and auxiliary functions in our shader. We specify a file where these variables and functions are defined and the shader will be able to compile them in the code.

For example `#include "UnityCG.cginc"` import a file located in unity install folder (Unity_install_path/Data/CGIncludes/UnityCG.cginc). If we open this file, we see that variables and functions are declared in it. When we include the file in the shader with `#include` all of these functions become available and compilable in our shader code.

**The link below open UnityCG.cginc to check the variables and functions that are defined in it:**  
[See UnityCG.cginc content](UnityCG.cginc)

Here is some example of functions declared in UnityCG.cginc that are used in the default unlit shader:

- `UNITY_FOG_COORDS(T)`
- `UnityObjectToClipPos(V)`
- `TRANSFORM_TEX(T, S)`
- `UNITY_TRANSFER_FOG(O, C)`
- `UNITY_APPLY_FOG(I, O)`

```c#
Shader "..."
{
    Properties { ... }

    SubShader
    {
        ...
        Pass
        {
            CGPROGRAM

            //Pragmas
            ...

            #include "UnityCG.cginc"

            struct appdata
            {
                ...
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                // UNITY_FOG_COORDS() is declared in UnityCG.cginc, only compile if UnityCG.cginc is included
                UNITY_FOG_COORDS(1);
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                // UnityObjectToClipPos() is declared in UnityCG.cginc, only compile if UnityCG.cginc is included
                o.vertex = UnityObjectToClipPos(v.vertex); 

                // TRANSFORM_TEX() is declared in UnityCG.cginc, only compile if UnityCG.cginc is included
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // UNITY_TRANSFER_FOG() is declared in UnityCG.cginc, only compile if UnityCG.cginc is included
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                // UNITY_APPLY_FOG() is declared in UnityCG.cginc, only compile if UnityCG.cginc is included
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }

            ENDCG
        }
    }
}
```

> Another example of variable included in UnityCG.cginc is `UNITY_PI` that allows use to use the value of Pi.       

## Create custom cginc file

It's possible to create our own .cginc file to declare custom variables and functions. We just need to create a new file, declare our variables/functions, save the file with the extension ".cginc" and use #include to include the file in the code.

Here is an example of a simple custom .cginc that just declare a variable for red, green and blue color:

```c#
// We define 3 custom variables to keep the red, green and blue color values
#define CUSTOMCG_RED fixed4(1, 0, 0, 1)
#define CUSTOMCG_GREEN fixed4(0, 1, 0, 1)
#define CUSTOMCG_BLUE fixed4(0, 0, 1, 1)
```

And here a shader example where we include and use this custom .cginc. In this example the .cginc file is placed in a dedicated folder inside the Assets directory of a unity project.

```c#
Shader
{
    Properties { ... }

    SubShader
    {
        ...
        Pass
        {
            CGPROGRAM

            //Pragmas
            ...

            #include "UnityCG.cginc"
            // We include a custom .cginc file included in the unity project in "Assets/Cginc/" folder 
            #include "Assets/Cginc/CustomCG.cginc" 

            // appdata and v2f structs
            ...

            // Connection variables
            ...

            v2f vert (appdata v)
            {
                ...
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                // Use variables from the custom Cginc file to change the color of the texture
                col *= CUSTOMCG_RED + CUSTOMCG_GREEN;

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
```   