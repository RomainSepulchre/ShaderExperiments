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
	
	// Like an FBM, we iterate on the UV and with each new octaves we modify further the turbulence matrix
	// and the frequency
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
    
    //uv = sineWave(uv, turbSpeed);
    uv = turbulence(uv, turbSpeed);

	
    // Use exp() to create a non linear gradient
    // -> Increasing/decreasing the value of gradientColors allows to change the amount
    //	  of R,G,B in the gradient
    float3 gradientColors = float3(-1.0, 0.0, 2.0);
    gradientColors = float3(13.2, 7.0, -1.5); // Override default gradient
    
    float3 color = 0.5 * exp(0.1 * uv.x * gradientColors);
    
    
    // Change the brighness based on turbulence values
    color /= dot(cos(uv * 3.0), sin(-uv.yx * 3.0 * 0.618)) + 2.0;
    
    // Ajust brighness with exponential tonemap
    // -> exponential tonemapping: compress high lights without crushing them while preserving details in dark and bright spot
    float exposure = 1.0;
    color = 1.0 - exp(-color * exposure);
    
    //return float4(uv.xy, 0, 1);
    return float4(color, 1);
    
    
    
}
