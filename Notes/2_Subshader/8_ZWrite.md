# ZWrite

**Links:**

- https://docs.unity3d.com/6000.2/Documentation/Manual/SL-ZWrite.html

## ZWrite

This command controls the writing of the surface pixels of an object to the Z-Buffer. This means it allows us to ignore or respect the depth distance between the camera and an object.

When working with transparent objects we usually want to disable Z-Buffer to prevent Z-Fighting issue. Z-Fighting happens when several objects are at the same distance from camera, thay have an identical Z-Buffer value that prevent the GPU to know which object is on front.

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
        ZWrite Off

        Pass
        {
            ZWrite Off // can be defined in a pass have a specific setting in it
            ...
        }
    }
}
```

### ZWrite mode

- `ZWrite Off` = for transparency
- `ZWrite On` = default value

### Use a toggle to change ZWrite dynamically

ZWrite can be enable/disabled dynamically from the inspector with a Toggle property.

```c#
Shader
{
    Properties
    {
        [Toggle] _ZWrite ("ZWrite", Float) = 0
    }
    SubShader
    {
        ...
        ZWrite [_ZWrite]

        Pass
        {
            ...
        }
    }
}
```


