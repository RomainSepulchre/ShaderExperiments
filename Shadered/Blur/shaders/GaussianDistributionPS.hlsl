cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform Texture2D mainTex : register(t0);
uniform SamplerState mainTex_ST : register(s0);

// Gaussian distribution:
// -> This distribution allow to smooth value to get a more natural and smoother looking blur
// -> x: represent the distance from center texel
// -> sigma: represent the range of the distribution (high value produce smoother result and low value sharper result)
float gaussian(in float2 x, in float sigma)
{
	return 0.3989423 * exp(-0.5 * dot(x,x) / (sigma * sigma)) / sigma;
}

// Same code as the box blur but instead of using a predefined weight we use gaussian distribution to calculate the weight of every pixels
float4 blur(Texture2D tex, SamplerState tex_ST, float2 uv, float2 texel, int range)
{
	float4 texSum = 0.0;
	float weightSum = 0.0;
	
	// Sample around pixel
	for(int i = -range; i <= range; i++)
	{
		for(int j = -range; j <= range; j++)
		{
			float weight = gaussian(float2(i,j), 6.0); // Gaussian distribution is used to define the weight
			texSum += tex.Sample(tex_ST, uv + float2(i,j) * texel) * weight;
			weightSum += weight;
		}
	}
	
	// return average
	return texSum / weightSum;
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 texel = 1.0 / uResolution;
    float2 uv = fragCoord.xy * texel;
	
	float3 color = blur(mainTex, mainTex_ST, uv, texel * 10, 4.0);
	
	return float4(color, 1.0);
}
