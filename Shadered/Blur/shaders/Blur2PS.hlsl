cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform Texture2D rt_blur1Tex : register(t0);
uniform SamplerState rt_blur1_ST : register(s0);


float4 blur(Texture2D tex, SamplerState tex_ST, float2 uv, float2 texel, int range)
{
	float4 texSum = 0.0;
	float weightSum = 0.0;
	
	// Sample around pixel
	for(int i = -range; i <= range; i++)
	{
		for(int j = -range; j <= range; j++)
		{
			texSum += tex.Sample(tex_ST, uv + float2(i,j) * texel);
			weightSum += 1.0;
		}
	}
	
	// return average
	return texSum / weightSum;
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
	float2 texel = 1.0 / uResolution;
    float2 uv = fragCoord.xy * texel;     

    float4 blurTex1 = blur(rt_blur1Tex, rt_blur1_ST, uv, texel * 10, 4.0);
    
	return blurTex1;
}
