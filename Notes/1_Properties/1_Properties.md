# Properties

**Links:**

- https://docs.unity3d.com/6000.2/Documentation/Manual/SL-Properties.html

## Properties Block

The properties block is a section where you can define properties that will have an impact on your shader. These properties appear in the material inspector and you can change their value from the inspector.

```c#
Shader "..."
{
    Properties
    {
        // Declare properties here...
    }
    SubShader
    {
        ...
    }
}
```

The syntax to declare a property is :

```c#
_PropertyName ("Display Name", Type) = defaultValue
```

- PropertyName: name of the property in the code (as a convention property name usually have a _ prefix)
- "Display Name" = name of the property displayed in the inspector
- Type = the type of the property (ex: color, vector, texture, float, int, etc)

>⚠️Properties are not closed with an ; contrary to c# instructions

## Type of properties

### 2D Texture

```c#
_Texture ("Texture Example", 2D) = "white" {}
```

### Color

```c#
_Color ("Color Example", Color) = (1,1,1,1) // (R,G,B,A)
```
        
### Range

```c#
_Range ("Range Example", Range(0, 100)) = 50
```
        
### Float

```c#
_Float ("Float Example", Float) = 0.999
```

### Int

```c#
_Int ("Int Example", Int) = 999
```
        
### Vector

```c#
_Vector ("Vector Example", Vector) = (0,0,0,1) //(X,Y,Z,W) when W=1 -> point in space, when W=0 -> direction
```
        
### CubeMap

```c#
_Cubemap ("Cubemap Example", Cube) = "black" {}
```
        
### 3D Texture

```c#
 _3DTexture ("3D Texture Example", 3D) = "white" {} 
```