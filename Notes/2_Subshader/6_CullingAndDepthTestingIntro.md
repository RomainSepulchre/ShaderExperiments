# Culling and depth test introduction

**Links:**

- 

## Culling and depth test introduction

Every pixels have a color value but thay also have a depth value called Z-Buffer or Depth Buffer. The depth buffer store if an object goes in front or behind another on the screen. The Z-Buffer measure the depth of pixel in term of distance from camera, a pixel closer to the camera will have a lower Z-Buffer value and a pixel farther with have a higher Z-Buffer value.

Z-Buffer allows to know if a pixel need to be updated or not, During rendering pixels with a lower z-buffer value will overwrite the pixels with higher value.

We can modify the Z-Buffer values to generate visual effect using the Cull, ZWrite and ZTest command. Like Tags this can be done either in the subshader or in the pass to select at which level we want to use command.

For example, if we want to create a diamond shader we need two passes with different culling options:
- A first pass for the background color of the diamond
- A second pass for the brightness of the diamond surface 