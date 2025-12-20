# ZTest

**Links:**

- https://docs.unity3d.com/6000.2/Documentation/Manual/SL-ZTest.html

## ZTest

`ZTest` command controls how the depth testing is performed. When setting ZTest mode, we define an operation we want to use to compare Z-Buffer values. It is generally used in shaders with several passss to generate different colors and depths.

```c#
Shader
{
    Properties
    {
        ...
    }
    SubShader
    {
        ...
        ZTest Greater

        Pass
        {
            ZTest Greater // can be defined in a pass have a specific setting in it
            ...
        }
    }
}
```

### ZTest modes

- **Less**: (<) Draws the objects in front. Objects at the same distance or behind are ignored.
- **Greater**: (>) Draws the objects in behind. Objects at the same distance or in front are ignored.
- **LEqual**: (<=) Draws the objects in front or at the same distance. Objects behind are ignored (Default mode).
- **GEqual**: (>=) Draws the objects behind or at the same distance. Objects in front are ignored.
- **Equal**: (==) Draws the objects at the same distance. Object in front or behind are ignored.
- **NotEqual**: (!=) Draws objects that are not at the same distance. Objects at the same distance are ignored.
- **Always**: Draws all pixels regardless of their Z-Buffer value.