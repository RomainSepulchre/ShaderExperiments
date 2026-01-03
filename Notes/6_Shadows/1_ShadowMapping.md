# Shadow mapping

**Links:**

- https://www.opengl-tutorial.org/intermediate-tutorials/tutorial-16-shadow-mapping/
- https://en.wikipedia.org/wiki/Shadow_mapping
- https://docs.unity3d.com/2022.3/Documentation/Manual/shadow-mapping.html

## Shadow mapping concept

Shadow mapping is a simple concept, we use the frustum of the light source to generate a map of the light and shadow areas. This means that the shadow projection of a directional light will be orthographic while the shadow projection of a point light or spot light will be rendered in perspective.

To calculate that we compare if a pixel is visible from the light source, if it isn't then another object block the light and the pixel must be a shadow.

<img src="https://www.opengl-tutorial.org/assets/images/tuto-16-shadow-mapping/shadowmapping.png" alt="Shadow mapping representation" width="400"/>

To have a fully functional shadow mapping we need two things:
- A [shadow caster](./2_ShadowCaster.md): the shadow area projected by an object
- A [shadow map](./3_ShadowMap.md): the shadow cast on an object

In term of shader it means we need to implement 2 pass:

- one pass that cast shadows onto other objects (Shadow caster)
- one pass to receive shadow cast by other objects (Shadow map)

### Pass specificities

Both pass must declare the `LightMode` in the Tags with specific value:

- The shadow caster pass must declare `"LightMode"="ShadowCaster"`. Using `ShadowCaster` as value allow unity to know this is a shadow caster pass.
- The default color pass that will handle the shadow map must declare `"LightMode"= "ForwardBase"`. Using `ForwardBase` as value allow unity to know this pass is affected by lighting

```c#
Shader ""
{
    ...

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        // Shadow caster pass: will handle shadow projection
        Pass
        {
            Name "Shadow Caster"
            Tags
            {
                "LightMode"="ShadowCaster" // Add the LightMode tag and set it to "ShadowCaster" so unity will recognize the pass as a shadow casting pass
            }
            
            ZWrite On

            ...
        }

        // Default color pass: will handle shadow map
        Pass
        {
            Name "Shadow Map Texture"
            Tags
            {
                "LightMode"= "ForwardBase" // Set the LightMode to ForwardBase to let Unity know this pass is affected by lighting
            }

            ...
        }
    }
}
```

**Name of the pass**

In the example above we also declare a name for each pass. Naming is used for organization and to differentiate passes but it has no impact on shader rendering.

> A pass name call also be used to dynamically get the functionalities of a pass with the [`UsePass`](https://docs.unity3d.com/2021.3/Documentation/Manual/SL-UsePass.html) command.