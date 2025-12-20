# PowerSlider and IntRange Material Property Drawer

**Links:**

- https://docs.unity3d.com/6000.2/Documentation/ScriptReference/MaterialPropertyDrawer.html

## PowerSlider

PowerSlider is a property that generates a non-linear slider with curve control.

```c#
[PowerSlider(3)] _PowSlider ("Power Slider)", Range(0, 1)) = 0.5
```

The value provided for the power slider is the force of the response curve. For example with a 0 to 1 slider using a response curve of 3, 0.5 will be on the far right of the range instead of the middle of the range. This means, we will have way more precision when selecting a low value on the slider than when selecting a high value.

## IntRange

IntRange adds a range slider of integer values. It is a classic slider but it restrict the value in the range to integer.

```c#
[IntRange] _IntRange ("Int Range", Range(0,255)) = 100
```