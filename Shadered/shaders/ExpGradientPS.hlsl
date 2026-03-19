cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = (fragCoord.xy / uResolution);
    
    float t = uv.x;
    float exponent = 4.0;
    float offset = 1.0;
	float exp_t = exp(-exponent * t + offset);
	float3 color = lerp(float3(1.0, 0.0, 0.0), float3(0.0, 0.0, 1.0), exp_t);
    

    return float4(color * 0.25, 1);
    
}