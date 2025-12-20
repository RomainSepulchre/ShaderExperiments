# Enum Material Property Drawer

**Links:**

- https://docs.unity3d.com/6000.2/Documentation/ScriptReference/MaterialPropertyDrawer.html

## Enum property

The difference between a KeywordEnum and an Enum is that Enum allows to define more than one value/id. The id/value set can be passsed to a command in the shader so they can be run dynamically from the inspector.

To define our Enum states we write the name of a state and his value separated by a **,**. To add the next state we just separate them with another **,**. 

```c#
[Enum(State1, 0, State2, 1, State3, 2)] _MyEnumProperty ("My Enum Property", Float) = 1
```

To use the property as a command parameter we write the name of the property between **[]**.

```c#
// we use the Cull command for the example
Cull [_MyEnumProperty]
```

### Example: Set the value of the Cull command with an Enum

```c#
Shader "..."
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        // Enum property
        [Enum(Off, 0, Front, 1, Back, 2)] _CullFace ("Cull Face", Float) = 1
    }
    SubShader
    {
        ...

        // Enum: instead of defining a value for the Cull command in the shader code, we use our enum to define it dynamically from the inspector
        Cull [_CullFace]

        Pass
        {
            ...
        }
    }
}
```

## Use an existing enum to set states

Instead of setting your own values you can use the values of an existing enum by using its type with the full namespace path. This is especially useful to use the exact enum states of a specific command.

```c#
// Blending
[Enum(UnityEngine.Rendering.BlendMode)] _BlendModes ("Blend Modes", Float) = 1

// Cull
[Enum(UnityEngine.Rendering.CullMode)] _CullModes ("Cull Modes", Float) = 1

// ZTest
 [Enum(UnityEngine.Rendering.CompareFunction)] _ZTestMode ("ZTest Mode", Float) = 1
```