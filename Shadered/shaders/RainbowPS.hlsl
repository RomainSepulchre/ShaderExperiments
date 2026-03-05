cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
	float2 uv = fragCoord.xy/uResolution;
	
	float rStep = 1.0 / 6.0;
    float rMask1 = smoothstep(0.0, 0.0, uv.y) - smoothstep(0.0, rStep, uv.y);
    float rMask2 = smoothstep(0.0, rStep, uv.y) - smoothstep(rStep, rStep*2, uv.y);
    float rMask3 = smoothstep(rStep, rStep*2, uv.y) - smoothstep(rStep*2, rStep*3, uv.y);
    float rMask4 = smoothstep(rStep*2, rStep*3, uv.y) - smoothstep(rStep*3, rStep*4, uv.y);
    float rMask5 = smoothstep(rStep*3, rStep*4, uv.y) - smoothstep(rStep*4, rStep*5, uv.y);
    float rMask6 = smoothstep(rStep*4, rStep*5, uv.y) - smoothstep(rStep*5, rStep*6, uv.y);
    float rMask7 = smoothstep(rStep*5, rStep*6, uv.y);
    
    float3 color = 0.0;
    color += float3(0.384, 0.18, 0.541) * rMask1; // Purple
    color += float3(0.027, 0.431, 0.702) * rMask2; // Indigo
    color += float3(0.0, 0.647, 0.902) * rMask3; // Blue
    color += float3(0.439, 0.796, 0.247) * rMask4; // Green
    color += float3(0.949, 0.937, 0.071) * rMask5; // Yellow
    color += float3(0.929, 0.608, 0.106) * rMask6; // Orange 
    color += float3(0.949, 0.075, 0.082) * rMask7; // Red

    return float4(color, 1.0f);
}