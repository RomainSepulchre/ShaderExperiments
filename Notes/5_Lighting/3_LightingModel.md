# Lighting model

**Links:**

-

## What is a Lighting model ?

A lighting model is the result of all the interactions between an object surface and the light source. By definition, this include the light properties (color, intensity, etc) and the object material properties.

We can differentiate 2 ways to calulate the illumination: per-vertex lighting and per-fragment/per-pixel lighting.

### Per-vertex lighting

The illumination is calculated for each vertices and is the calculation is performed in the vertex shader (`vert()`).

### Per-fragment/per-pixel lighting

The illumination is calculated for each pixels and is the calculation is performed in the fragment shader (`frag()`).