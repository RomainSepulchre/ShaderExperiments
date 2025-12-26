// Shader that use _Time, _SinTime and _CosTime built-in variables to show how they works

// Built-in variables are global variables included in Unity that you can use in your shader code. They give you access to things like
// the current object’s transformation matrices, the light parameters, the current time and so on.

// See https://docs.unity3d.com/540/Documentation/Manual/SL-UnityShaderVariables.html

// _Time, _SinTime and _CosTime

// -> _Time, _SinTime and _CosTime give you access to your app time value. The time is measured in seconds and scaled by the "Time multiplier" 
//    parameter of the project "Time Settings".
// -> All the time built-in variables are four dimensions vector, each component of the vector returns a different time value:
//      - _Time: time since the level load (similar to Unity Time.timeSinceLevelLoad)
//          - _Time.x = t/20
//          - _Time.y = t
//          - _Time.z = t*2
//          - _Time.w = t*3
//      - _SinTime: Sine of the time 
//          - _SinTime.x = t/8
//          - _SinTime.y = t/4
//          - _SinTime.z = t/2
//          - _SinTime.w = t ( => sin(_Time.y) )
//      - _CosTime: Cosine of the time
//          - _CosTime.x = t/8
//          - _CosTime.y = t/4
//          - _CosTime.z = t/2
//          - _CosTime.w = t ( => cos(_Time.y) )
//      - _unity_DeltaTime: Delta time (time of the frame)
//          - _unity_DeltaTime.x = dt
//          - _unity_DeltaTime.y = 1/dt
//          - _unity_DeltaTime.z = smoothDt
//          - _unity_DeltaTime.w = 1/smoothDt

// -> The time built-in variable can be use to control the timing and animate our shader
//    of the normal and the light direction.

// -> In this shader we use _Time and _SinTime/_CosTime to animate the UV coordinate and create a texture scroll animation

Shader "LearnShader/CG_HLSL/Intrinsic Functions/Time SinTime CosTime (BIRP_Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // KeywordEnum to choose between _Time and _SinTime/_CosTime
        [KeywordEnum(Time, SinCosTime)] _TimeAnim ("Time Animation", float) = 0
        
        // Speed property
        _Speed ("Speed", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            #pragma shader_feature _TIMEANIM_TIME _TIMEANIM_SINCOSTIME

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            float _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
            #if _TIMEANIM_TIME
                // Animate u coordinate
                i.uv.x += _Time.y;
            #elif _TIMEANIM_SINCOSTIME
                // Animate u coordinate with SinTime and v coordinate with CosTime
                i.uv.x += _SinTime.w;
                i.uv.y += _CosTime.w;
            #endif
                
                fixed4 col = tex2D(_MainTex, i.uv);

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
