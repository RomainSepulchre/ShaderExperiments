# Specular Reflection

**Links:**

- 

## ## What is a Specular reflection ?

The specular reflection define the way light is reflected in a specific direction, contrary to diffuse reflection which disperse light, the specular reflection create sharp reflection that depends on the angle of view.

![Representation of diffuse and specular reflection on a glossy surface](https://upload.wikimedia.org/wikipedia/commons/b/bd/Lambert2.gif)

In real-time 3D, Phong model adds specular reflections add a specular brightness to a surface according to the position of its normal.

## How to calculate the Specular reflection ?

The formula to calculate the specular reflection is:

$S = S_a * S_p * max(0, dot(H, N)^2)$

or to simplify:

> *Specular* = *Reflection color of light source* ⋅ *specular intensity* ⋅ max(0, dot(*halfway*, *surface normal*)^2)

The big difference between diffuse and specular reflections is the *H* vector we use in the calculation. It refers to a half vector called halfway.

We need *H* because if the specular reflection has the same angle as the light direction, we are only able to see the reflection when the camera is in the same direction. To solve this we calculate *H* to be an intermediate between the normal and the light direction, following the view direction.

$H = L + E / magnitude(L + E)$
> *Halfway* = *Light direction* + *view direction* / magnitude(*Light direction* + *view direction*)

Since we always use normalized vectors we can even simplify the operation:

$H = normalize(L + E)$
>Halfway = normalize(Light direction + view direction)

## Implement specular reflection in a shader

If we translate the formula to code, we can define a function that calculate the specular reflection:

```c#
float3 SpecularShading(float3 colorRefl, float specularInt, float3 normal, float3 lightDir, float3 viewDir, float specularPow)
{
    float3 h = normalize(lightDir + viewDir); // halfway
    
    return colorRefl * specularInt * pow(max(0, dot(normal, h)), specularPow);
}
```

So, if we want to add diffuse reflection to our shader we need to get 6 informations: the *reflection color of the light*, the *specular intensity*, the *normal of the surface*, the *direction of the light*, the *direction of the view* and the *specularity exponent*.

We also need to add a *specular texture map* to define where on the object the specular reflection should happen.

### Specular texture, specular intensity and specularity exponent

Those 3 parameters are properties that we need to add to our shader. 

```c#
Properties
{
    _MainTex ("Texture", 2D) = "white" {}
    
    // Specular properties
    _SpecularTex ("Specular Texture", 2D) = "black" {} // black so no specular reflection added when there is no texture
    _SpecularInt ("Specular Intensity", Range(0,1)) = 1
    [IntRange] _SpecularPow ("Specular Power", Range(1, 128)) = 64
}
```

We also need to declare a connection variable inside CGPROGRAM to be able to use the property later in the code.

```c#
CGPROGRAM
// Pragma and include
...

// Appdata and v2f struct
...

// Connection variables
sampler2D _SpecularTex;
float _SpecularInt;
float _SpecularPow;

// DiffuseShading(), vert() and frag()
...

ENDCG
```

### Color Reflection

To define reflection color we can use `_lightColor[n]`. It is an internal variable that refers to the color of the scene lighting.

⚠️ To use `_lightColor[n]` we need to declare it as a uniform variable in the CGPROGRAM next to the connection variables. Once it is declared we can use it later in the code.

```c#
// Internal variable
float4 _LightColor0; // internal variable that refers to scene lighting color
```


=> specular texture to define where to enable specular reflection


### Surface normal and view direction (world-space)



### Light direction (world-space)

To define the direction of the light in world-space we can use another internal variable `_WorldSpaceLightPos[n]`. Contrary to `_lightColor[n]` we don't have to declare it has a uniform variable because the variable is already initialized inside *UnityCG.cginc*.

```c#
float3 lightDir = normalize(_WorldSpaceLightPos0.xyz)
```

We normalize the vector to ensure it will have a magnitude of 1 and we store the X,Y and Z coordinates in a `float3`.