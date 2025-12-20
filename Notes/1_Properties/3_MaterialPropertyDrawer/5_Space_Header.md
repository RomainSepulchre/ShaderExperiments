# Space and Header Material Property Drawer

Header and Space are similar to the attributes with the same name in c#, they're useful to organize the property in the inspector.

**Links:**

- https://docs.unity3d.com/6000.2/Documentation/ScriptReference/MaterialPropertyDrawer.html

## Space

Add a space between two property. The value you specify is the size of the space.

```c#
[Space(10)]
```

## Header

Add a header before the property. The value you specify is the text of the header. 

```c#
[Header(My Header)]
_MainTex ("Main Texture", 2D) = "white" {}
```