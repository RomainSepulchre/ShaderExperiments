// Based on https://mini.gmshaders.com/p/turbulence

cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform float uvScale;
uniform float4 turbMatrix;
uniform float turbFreq;
uniform float turbAmp;
uniform float turbSpeed;
uniform float turbCount;
uniform float turbExp;
uniform float4 d;

float2 sineWave(float2 uv, float speed)
{
	// Sine wave displasment
    
    float amplitude = turbAmp;
    float frequency = turbFreq;
    
    float phase = frequency * (uv * turbMatrix).y + speed * uTime;
    
    uv +=  amplitude * turbMatrix[0] * sin(phase) / frequency;
    
    return uv;
}

float2 turbulence(float2 uv, float speed)
{
	float2x2 rotMatrix = turbMatrix;
	float frequency = turbFreq;
	float amplitude = turbAmp;
	
	for(float i=0.0; i < turbCount; i++)
	{
		float phase = frequency * (uv * rotMatrix).y + speed * uTime + i;
   		 uv +=  amplitude * rotMatrix[0] * sin(phase) / frequency;
   		 
		rotMatrix *= turbMatrix;
		frequency *= turbExp;
	}
	return uv;
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = uvScale * (fragCoord.xy * uvScale - uResolution) / uResolution.y ;
    
    uv = turbulence(uv, turbSpeed);
    //uv = sineWave(uv, turbSpeed);
    
    return float4(uv.xy, 0, 1);
    
    return float4(0.5f + 0.5f*cos(uTime+uv.yxy), 1.0f);
}
