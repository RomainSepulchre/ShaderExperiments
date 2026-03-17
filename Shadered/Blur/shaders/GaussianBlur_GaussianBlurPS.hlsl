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
float gaussian(in float x, in float sigma)
{
	return 0.39894 * exp(-0.5 * x * x / (sigma * sigma)) / sigma;
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    
    float4 tex = mainTex.Sample(mainTex_ST, uv);
    
    float3 color = tex.rgb;
    
    const int mSize = 10;
    const int kSize = (mSize-1)/2; // == 4
    
    float kernel[mSize];
    
    float3 blurColor = 0.0;
    
    float sigma = 7.0;
    float weightSum = 0.0;
    
    int t = kSize;
    
    // Calculate and store weight values
    for (int i = 0; i <= kSize; i++)
	{
		kernel[kSize + i] = kernel[kSize - i] = gaussian(float(i), sigma);
	}
	
	// Calculate the sum of all the weights
	for (int i = 0; i < mSize; i++)
	{
		weightSum += kernel[i];
	}
	
	// Sample texels and apply the weigth
	for (int i=-kSize; i <= kSize; ++i)
	{
		for (int j=-kSize; j <= kSize; ++j)
		{
			float2 kernelUv = (fragCoord.xy + float2(i,j)) / uResolution;
			blurColor += kernel[kSize+j] * kernel[kSize+i] * mainTex.Sample(mainTex_ST, kernelUv).rgb;
		}
	}
	
	// Get average value as color
	color = float4(blurColor / (weightSum * weightSum), 1.0);
	
	return float4(color, 1.0);
}
