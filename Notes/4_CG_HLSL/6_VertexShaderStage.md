# CG / HLSL Vertex Shader Stage

**Links:**

- ...

## Vertex Shader Stage

The vertex shader stage is a programmable render pipleline stage where the objects vertices are transformed from a 3D space to a 2D projection on the screen. Its smallest unit of calculation is an independent vertex.

`vert()` correspond to the Vertex Shader Stage because of the directive `#pragma vertex vert`, without this pragma directive the GPU no longer knows that `vert()` is the Vertex Shader Stage.

```c#
v2f vert (appdata v)
```
When we look at `vert() `function signature we can see 2 things:
    - `vert()` return an object of type `v2f` that correspond to the `v2f` (vertex to fragment) struct defined previously
    - `vert()` argument is an object of type `appdata` that correspond to the `appdata` struct defined previously

This means `vert()` use the data from the `appdata` argument and output the data processed in `v2f`.

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

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            //Include
            ...

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1);
                float4 vertex : SV_POSITION;
            };

            //Connection variables
            ...

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
                ...
            }

            ENDCG
        }
    }
}
```

## Rename the Vertex Shader Stage function

When we declare `#pragma vertex vert` we end the declaration by the name of the function that correspond to the vertex shader stage. So in fact we can give the name we want to the function that act as the vertex shader stage.

So if I declare my `#pragma vertex` with a specific name like this:

```c#
#pragma vertex vertexshaderstage // = #pragma vertex nameOfFunction
```

I can then rename `vert()` to the name I defined in `#pragma vertex ...`

```c#
v2f vertexshaderstage (appdata v)
{
    ...
}
```