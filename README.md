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
    - [Abs](Notes/4_CG_HLSL/10_IntrinsicFunctions.md#abs)
    - [Ceil](Notes/4_CG_HLSL/10_IntrinsicFunctions.md#ceil)
    - [Clamp](Notes/4_CG_HLSL/10_IntrinsicFunctions.md#clamp)
    - [Sin and Cos](Notes/4_CG_HLSL/10_IntrinsicFunctions.md#sin-and-cos)
    - [Tan](Notes/4_CG_HLSL/10_IntrinsicFunctions.md#tan)
    - [Exp, Exp2 and Pow](Notes/4_CG_HLSL/10_IntrinsicFunctions.md#exp-exp2-and-pow)
    - [Floor](Notes/4_CG_HLSL/10_IntrinsicFunctions.md#floor)
    - [Step and SmoothStep](Notes/4_CG_HLSL/10_IntrinsicFunctions.md#step-and-smoothstep)
    - [Length](Notes/4_CG_HLSL/10_IntrinsicFunctions.md#length)
    - [Frac](Notes/4_CG_HLSL/10_IntrinsicFunctions.md#frac)
    - [Lerp](Notes/4_CG_HLSL/10_IntrinsicFunctions.md#lerp)
    - [Min and Max](Notes/4_CG_HLSL/10_IntrinsicFunctions.md#min-and-max)
    - [_Time, _SinTime, _CosTime](Notes/4_CG_HLSL/10_IntrinsicFunctions.md#_time-_sintime-_costime)

- **Lighting**
    - [Normals](Notes/5_Lighting/1_Normals.md)
    - [Normal maps](Notes/5_Lighting/2_NormalMaps.md)
    - [lighting model](Notes/5_Lighting/3_LightingModel.md)
    - [Ambient color](Notes/5_Lighting/4_AmbientColor.md)
    - [Diffuse reflections](Notes/5_Lighting/5_DiffuseReflection.md)
    - [Specular reflection](Notes/5_Lighting/6_SpecularReflection.md)
    - [Environmental reflection](Notes/5_Lighting/7_EnvironmentalReflection.md)
    - [Fresnel effect](Notes/5_Lighting/8_FresnelEffect.md)
    - [Standard Surface shader](Notes/5_Lighting/9_StandardSurface.md)

- **Shadows**
    - [Shadow mapping](Notes/6_Shadows/1_ShadowMapping.md)
    - [Shadow caster](Notes/6_Shadows/2_ShadowCaster.md)
    - [Shadow map](Notes/6_Shadows/3_ShadowMap.md)
    - [URP Shadow mapping](Notes/6_Shadows/4_URP_ShadowMapping.md)