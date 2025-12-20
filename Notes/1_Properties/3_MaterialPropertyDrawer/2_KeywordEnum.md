# KeywordEnum Material Property Drawer

**Links:**

- https://docs.unity3d.com/6000.2/Documentation/ScriptReference/MaterialPropertyDrawer.html

## KeywordEnum Property

Where a toggle only allows for 2 state (true/false), a keyword enum allows to define up to 9 states and generate and dropdown selector in the inspector window that let you choose between different states to modify the shader.

```c#
[KeywordEnum(State1, State2, State3, State4)] _MyKeywordEnum ("_My Keyword Enum", Float) = 0
```

>❔Like a standard C# enum, the value of the enum is represented by an int.

## Use the keyword enum states in the shader

To use the keywordEnum states in the shader code we need to declare keywords for every state with `#pragma shader_feature` or `#pragma multi_compile`. To declare the keyword of an keywordEnum state we use the name of the property followed by _ and the name of the state all in capital.

```c#
[KeywordEnum(State1, State2, State3, State4)] _MyKeywordEnum ("_My Keyword Enum", Float) = 0
```

```c#
// Example with pragma shader_feature
#pragma shader_feature _MYKEYWORDENUM_STATE1 _MYKEYWORDENUM_STATE2 _MYKEYWORDENUM_STATE3 _MYKEYWORDENUM_STATE4

// Example with pragma multi_compile
#pragma multi_compile _MYKEYWORDENUM_STATE1 _MYKEYWORDENUM_STATE2 _MYKEYWORDENUM_STATE3 _MYKEYWORDENUM_STATE4
```

>❔When building the project `#pragma shader_feature` will only export the selected variant whereas `#pragma multi_compile` will export all variants found in the shader. This means `multi_compile` allows to change the keywordEnum value in a build at execution time while it's not possible with `shader_feature`.

Once the keyword have been declared, we can use them in shader code with #if to switch between different behaviour depending on the current state of the num.

```c#
#if _MYKEYWORDENUM_STATE1
    // Do this when state 1
#elif _MYKEYWORDENUM_STATE2
    // Do this when state 2
#elif _MYKEYWORDENUM_STATE3
    // Do this when state 3
#elif _MYKEYWORDENUM_STATE4
    // Do this when state 4
#endif
```

### Example: Change color with keywordEnum

```c#
Shader "..."
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        // KeywordEnum property with state to change object color 
        [KeywordEnum(Off, Black, Red, Green, Blue)] _TexColor ("Texture Color", Float) = 0
    }
    SubShader
    {
        ...

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            //
            #pragma multi_compile _TEXCOLOR_OFF _TEXCOLOR_BLACK _TEXCOLOR_RED _TEXCOLOR_GREEN _TEXCOLOR_BLUE

            // Include, appdata and v2f struct
            ...

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                ...
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);  // sample the texture

                // KeywordEnum - Multiply texture by a color depending on enum state
            #if _TEXCOLOR_OFF // = multiplied by white
                // No need to do anything
            #elif _TEXCOLOR_BLACK
                col *= float4(0.1,0.1,0.1,1);
            #elif _TEXCOLOR_RED
                col *= float4(1,0,0,1);
            #elif _TEXCOLOR_GREEN
                col *= float4(0,1,0,1);
            #elif _TEXCOLOR_BLUE
                col *= float4(0,0,1,1);
            #endif

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
```