# CG / HLSL Functions

**Links:**

- https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-functions

## Functions

Like in c#, in CG/HLSL it's also possible to declare functions to simplify the code. They are very similar to c# functions and can either be void or return a value.

Since CG/HLSL code runs from top to bottom, all functions must be declares before the place where they are called.

### Functions with return value

The syntax of a function that return a value is exactly the same as a c# function.

```c#
fixed3 UvToColor (float2 uv)
{
    fixed3 uvAsCol = float3(uv.x, uv.y, 0);
    return uvAsCol;
}
```

### Void functions

Void functions however works differently, you need to add declarations to characterize the functions arguments and you need to specify the precision type at the end of its name.

```c#
void functionName_precision (declaration type arg)
{
    arg = 0;
}
```

#### Precision type

Defining the precision type is mandatory with void functions otherwise the function won't compile. To define the precision you only need to add *_type* at the end of the function name (ex: `void MyFunction_float()`).

```c#
// float example
void MyFunction_float ( ... );

// half example
void MyFunction_half ( ... );
```

>❓ After testing the precision type doesn't seems to be required with CG code, is it only needed with HLSL ?

#### Argument declaration
    
The declarations you add before the argument determine if a value correspond to an input (`in`), an output (`out`), a global variable (`uniform`) or a constant (`const`).

```c#
void MyFunction_float (in float3 Normal, out float3 Out);
```

#### Example: function that create a color base on UV value

```c#
void UvToColor_fixed (in float2 uv, out fixed3 uvCol)
{
    fixed3 uvAsColGB = float3(0, uv.x, uv.y);
    uvCol = uvAsColGB;
}
```
            