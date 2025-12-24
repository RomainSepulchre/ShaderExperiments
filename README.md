# Summary of my notes on shaders

- **Properties**
    - [Properties](Notes/1_Properties/1_Properties.md)
    - [Connection variables](Notes/1_Properties/2_ConnectionVariables.md)
    - Material property drawer
        - [Toggle](Notes/1_Properties/3_MaterialPropertyDrawer/1_Toggle.md)
        - [KeywordEnum](Notes/1_Properties/3_MaterialPropertyDrawer/2_KeywordEnum.md)
        - [Enum](Notes/1_Properties/3_MaterialPropertyDrawer/3_Enum.md)
        - [PowerSlider and IntRange](Notes/1_Properties/3_MaterialPropertyDrawer/4_PowerSlider_IntRange.md)
        - [Space and Header](Notes/1_Properties/3_MaterialPropertyDrawer/5_Space_Header.md)

- **Subshader block and subshader command**
    - [Subshader block](Notes/2_Subshader/1_SubshaderBlock.md)
    - [Tags](Notes/2_Subshader/2_Tags.md)
        - *Queue Tag*
        - *Render Type tag*
    - [Blend](Notes/2_Subshader/3_Blend.md)
    - [AlphaToMask](Notes/2_Subshader/4_AlphaToMask.md)
    - [ColorMask](Notes/2_Subshader/5_ColorMask.md)
    - [Culling and depth testing introduction](Notes/2_Subshader/6_CullingAndDepthTestingIntro.md)
    - [Cull](Notes/2_Subshader/7_Cull.md)
    - [Stencil](Notes/2_Subshader/10_Stencil.md)
    - [Pass Block](Notes/2_Subshader/11_Pass.md)

- [Fallback](Notes/3_Fallback.md)

- **CG/HLSL Code**
    - [CGPROGRAM/HLSLPROGRAM](Notes/4_CG_HLSL/1_CGPROGRAM_HLSLPROGRAM.md)
    - [Data types](Notes/4_CG_HLSL/2_DataTypes.md)
    - [Pragmas](Notes/4_CG_HLSL/3_Pragmas.md)
    - [Include](Notes/4_CG_HLSL/4_Include.md)
    - [Vertex Input and Vertex Output (appdata and v2f struct)](Notes/4_CG_HLSL/5_VertextInput_VertexOutput.md)
    - [Vertex Shader Stage](Notes/4_CG_HLSL/6_VertexShaderStage.md)
    - [Fragment Shader Stage](Notes/4_CG_HLSL/7_FragmentShaderStage.md)
    - [Functions](Notes/4_CG_HLSL/8_Functions.md)
    - [CG to HLSL](Notes/4_CG_HLSL/9_CgToHlsl.md)

- **Intrinsic functions**
    - [Abs](Assets/Shaders/CG_HLSL/Intrinsic%20functions/Abs.shader)
    - [Ceil](Assets/Shaders/CG_HLSL/Intrinsic%20functions/Ceil.shader)
    - [Clamp](Assets/Shaders/CG_HLSL/Intrinsic%20functions/Clamp.shader)
    - [Sin and Cos](Assets/Shaders/CG_HLSL/Intrinsic%20functions/SinCos.shader)
    - [Tan](Assets/Shaders/CG_HLSL/Intrinsic%20functions/Tan.shader)
    - [Exp, Exp2 and Pow](Assets/Shaders/CG_HLSL/Intrinsic%20functions/ExpExp2Pow.shader)
    - [Floor](Assets/Shaders/CG_HLSL/Intrinsic%20functions/Floor.shader)
    - [Step and SmoothStep](Assets/Shaders/CG_HLSL/Intrinsic%20functions/StepSmoothstep.shader)
    - [Length](Assets/Shaders/CG_HLSL/Intrinsic%20functions/Length.shader)
    - [Frac](Assets/Shaders/CG_HLSL/Intrinsic%20functions/Frac.shader)
    - [Lerp](Assets/Shaders/CG_HLSL/Intrinsic%20functions/Lerp.shader)
    - [Min and Max](Assets/Shaders/CG_HLSL/Intrinsic%20functions/MinMax.shader)
    - [_Time, _SinTime, _CosTime](Assets/Shaders/CG_HLSL/Intrinsic%20functions/TimeSinTimeCosTime.shader)