cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
	float2 uv = fragCoord.xy/uResolution;
	
	// Flag
	float3 color = 0.0;
    color = float3(0.0, 0.0, 1.0) * step(uv.x, 0.33); // Blue
    color += step(uv.x, 0.66) - (step(uv.x, 0.33)); // White
    color += float3(1.0, 0.0, 0.0) * (1 - step(uv.x, 0.66)); // Red
    
    return float4(color, 1.0f);
}