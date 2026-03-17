cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform Texture2D mainTex : register(t0);
uniform SamplerState mainTex_ST : register(s0);

// Horizontal Blur
float4 horizontalBlur(Texture2D tex, SamplerState tex_ST, float2 uv, float2 texel, int range, float weights[9])
{
	float4 texSum = tex.Sample(tex_ST, uv) * weights[0];
	float weightSum = weights[0];
	
	// Loop through 8 texels on right and left 
	for(int i = 1; i <= range; i++)
	{
			texSum += tex.Sample(tex_ST, uv + float2(i,0) * texel) * weights[i];
			texSum += tex.Sample(tex_ST, uv - float2(i,0) * texel) * weights[i];
			weightSum += weights[i] * 2.0;
	}
	
	// return average
	return texSum / weightSum;
}

// Vertical Blur
float4 verticalBlur(Texture2D tex, SamplerState tex_ST, float2 uv, float2 texel, int range, float weights[9])
{

	float4 texSum = tex.Sample(tex_ST, uv) * weights[0];
	float weightSum = weights[0];
	
	// Loop through texels on top and bottom 
	for(int i = 1; i <= range; i++)
	{
			texSum += tex.Sample(tex_ST, uv + float2(0,i) * texel) * weights[i];
			texSum += tex.Sample(tex_ST, uv - float2(0,i) * texel) * weights[i];
			weightSum += weights[i] * 2.0;
	}
	
	// return average
	return texSum / weightSum;
}

// Horizontal + Vertical Blur
float4 blur(Texture2D tex, SamplerState tex_ST, float2 uv, float2 texel, int range, float weights[9])
{

	float4 texSum = tex.Sample(tex_ST, uv) * weights[0];
	float weightSum = weights[0];
	
	// Loop through texels on top and bottom 
	for(int i = 1; i <= range; i++)
	{
			texSum += tex.Sample(tex_ST, uv + float2(i,0) * texel) * weights[i];
			texSum += tex.Sample(tex_ST, uv - float2(i,0) * texel) * weights[i];
			texSum += tex.Sample(tex_ST, uv + float2(0,i) * texel) * weights[i];
			texSum += tex.Sample(tex_ST, uv - float2(0,i) * texel) * weights[i];
			weightSum += weights[i] * 4.0;
	}
	
	// return average
	return texSum / weightSum;
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
	// Since Gaussian distribution is a quite slow to calculate (-> exp() and division for every sample), instead we can use a precomputed
	// list of weights (often called "kernels").
	// -> Gaussian is distribution is symmetrical and gaussian(x,y) is the same as gaussian(x,0) * gaussian(0,y) so we can store only one axis
	//    of the weights and use it for both x and y positions

	// Precomputed gaussian weight value (sigma = 5.0) renormalized to a sum of 1.0
	float weights[9];
	weights[0] = 0.080497596;
	weights[1] = 0.078903637;
	weights[2] = 0.074308647;
	weights[3] = 0.067237244;
	weights[4] = 0.058453252;
	weights[5] = 0.048824260;
	weights[6] = 0.039182387;
	weights[7] = 0.030211641;
	weights[8] = 0.022381334;
	
    float2 texel = 1.0 / uResolution;
    float2 uv = fragCoord.xy * texel;
    
	// Horizontal Blur
	float3 color = horizontalBlur(mainTex, mainTex_ST, uv, texel, 8.0, weights);
	
	// Vertical Blur
	color = verticalBlur(mainTex, mainTex_ST, uv, texel, 8.0, weights);
	
	// Horizontal + Vertical blur
	color = blur(mainTex, mainTex_ST, uv, texel, 8.0, weights);
	
	return float4(color, 1.0);
}
