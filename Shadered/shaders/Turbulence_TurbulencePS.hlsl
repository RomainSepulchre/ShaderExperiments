// Based on https://mini.gmshaders.com/p/turbulence

cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform float uvScale;
uniform float4 rotMatrix;
uniform float turbFreq;
uniform float turbAmp;
uniform float turbSpeed;
uniform float4 d;

float2 sineWave(float2 uv, float speed)
{
	// Sine wave displasment
    
    float amplitude = turbAmp;
    float frequency = turbFreq;
    
    float phase = frequency * (uv * rotMatrix).y + speed * uTime;
    
    uv +=  amplitude * rotMatrix[0] * sin(phase) / frequency;
    
    return uv;
}

float2 turbulence(float2 uv, float speed)

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = (fragCoord.xy/uResolution) * uvScale;
    
    uv = sineWave(uv, turbSpeed);
    
    return float4(uv.xxx, 1);
    
    return float4(0.5f + 0.5f*cos(uTime+uv.yxy), 1.0f);
}
