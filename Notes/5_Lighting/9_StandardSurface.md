# Standard Surface Shader

**Links:**

- https://docs.unity3d.com/Manual/SL-SurfaceShaders.html
- https://docs.unity3d.com/6000.2/Documentation/Manual/surface-shaders-language-reference-input-structure.html

## What is a standard surface shader ?

Contrary to a vertex-fragment shader, the standard surface shader has Global lighting, diffusion, reflection and fresnel implemented internally by default. This mean we don't have to do all these lighting operations ourself.

A standard surface shader has a different structure compare to a vertex-fragment shader. The main difference are:
- **No `pass{}` section**: the standard surface shader doesn't have a `pass{}` section, `CGPROGRAM` is written directly in the` subshader{}` section.
- **`#pragma surface surf`**: in a standard surface shader there is no `#pragma vertex vert` or `#pragment fragment frag`, we only declare `#pragma surface surf` that define the color output function.
- **Different inputs and outputs**: in a standard surface shader the inputs and outputs are no longer the `appdata` and `v2f` struct, instead we have an `Input` and a `SurfaceOutputStandard` struct.

## #pragma surface surf

Like we said previously in a standard surface shader, `#pragma vertex vert` and `#pragment fragment frag` are both replace by one pragma statement: `#pragma surface surf`. This pragma declare that the `surf()` function is the color output function.

```c#
#pragma surface surf Standard fullforwardshadows
```

As we can see `#pragma surface surf` has additional argument compared to `#pragma vertex vert` and `#pragment fragment frag`:
- `Standard` is a parameter that define the lighting model. The [common light model are](https://docs.unity3d.com/6000.2/Documentation/Manual/surface-shaders-language-reference-required-directives.html): `Standard`, `Lambert`, `BlinnPhong` and `StandardSpecular`.
- `fullforwardshadows` is an optionnal parameter that enable the support of shadows from directional, point, and spot lights in Forward Rendering ([here is a list of the optionnal directive](https://docs.unity3d.com/6000.2/Documentation/Manual/surface-shaders-language-reference-optional-directives.html))

## surf()

The `surf()` function declared with `#pragma surface surf` will define all our object surface properties and the vertex/fragment shader will be automatically generated from it.

```c#
void surf (Input IN, inout SurfaceOutputStandard o)
{
    // Set Albedo from a texture tinted by color
    fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
    o.Albedo = c.rgb;
    // Set Metallic and Smoothness from slider variables
    o.Metallic = _Metallic;
    o.Smoothness = _Glossiness;
    // Set Alpha
    o.Alpha = c.a;
}
```

`surf()` has 2 arguments: `input IN` and `SurfaceOutputStandard o`, they are two struct that refers to the shader inputs and outputs and their semantics is defined internally in the code.

Basically, in `surf()` we set the value of the `SurfaceOutputStandard` output and those output value will be use to define how our object should be rendered.

## Input and SurfaceOutputStandard struct (Input/Output)

### Input struct (Input)

`Input` is the input struct but it is similar as `appdata` but it works differently.

In `appdata` we can define our object semantics and bind them to an input variable while in `Input` we determine our the shader predefined functions used for lighting calculation we need. This means in `Input` we don't have to bind our variable to a semantic, however we need to use specific variable name that refers to a specific input data.

 Here is a list of all the reference we can use to get value inside the `Input`: https://docs.unity3d.com/6000.2/Documentation/Manual/surface-shaders-language-reference-input-structure.html

```c#
struct Input
{
    float2 uv_MainTex; // TEXCOORD0
    float3 viewDir; // View direction in world-space
    float4 Color : COLOR; // Vertex color, this an exception where a semantic is needed
    float3 worldPos; // vertex position in world-space
    float3 worldNormal; // normal in world-space
};
```

In the example above `viewDir`, `worldPos` and `worldNormal` will have the same value we calculated manually when working on vertex-fragment shader lighting:
 - `viewDir` = `normalize(_WorldSpaceCameraPos - i.vertex_world);`
 - `worldPos` = `mul(unity_ObjectToWorld, v.vertex);`
 - `worldNormal` = `normalize(mul(unity_ObjectToWorld, flaot4(v.normal, 0))).xyz;`

 ### SurfaceOutputStandard (Output)

 This struct type define all the color output that are used by the standard lighting model. It represent all the parameters that are used to describe how the object surface will be rendered and how light will interact with it.

`SurfaceOutputStandard` struct is not defined inside `CGPROGRAM`, it is defined internally and all the variables are already predefined. [Here is the structure of the surface output shader](https://docs.unity3d.com/6000.2/Documentation/Manual/SL-SurfaceShaders-output.html).

Here is the list of the variables defined inside `SurfaceOutputStandard`:

```c#
struct SurfaceOutputStandard
{
    fixed3 Albedo;
    fixed3 Normal;
    half3 Emission;
    half Metallic;
    half Smoothness;
    half Occlusion;
    fixed Alpha;
};
```

For example if I assign a specific color value to `Albedo` inside `surf()`, the object will be rendered with the color value I assigned.

```c#
void surf (Input IN, inout SurfaceOutputStandard o)
{
    o.Albedo = fixed3(1,1,1); // Color of the object will be white
    o.Metallic = 1; // Metallic of the object will have a value of 1
    o.Smoothness = 1; // Smoothness of the object will have a value of 1
    o.Alpha = 1; // Alpha of the object will have a value of 1
}
```

