cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform Texture2D rt_tex0 : register(t0);
uniform SamplerState rt_tex0_ST : register(s0);

uniform Texture2D rt_tex1 : register(t1);
uniform SamplerState rt_tex1_ST : register(s1);

uniform Texture2D rt_tex2 : register(t2);
uniform SamplerState rt_tex2_ST : register(s2);

uniform Texture2D rt_tex3 : register(t3);
uniform SamplerState rt_tex3_ST : register(s3);

uniform int uRange;
uniform float uJump;

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
	
	float2 uv = fragCoord.xy / uResolution * 2;
	
	float2 splitUv = frac(uv);

	float2 texel = 1.0 / uResolution;
    float2 texUv = splitUv * texel;  
    
    float4 noBlur = rt_tex0.Sample(rt_tex0_ST, uv); // Original texture, no blur
    float4 blur1 = rt_tex1.Sample(rt_tex1_ST, uv); // Simple box blur
    // Approximation of gaussian blur:
    // -> The more we iterate, the more we are getting close to an actual gaussian blur
    float4 blur2 = rt_tex2.Sample(rt_tex2_ST, uv); // We iterate with a new box blur on the initial box blur
    float4 blur3 = rt_tex3.Sample(rt_tex3_ST, uv); // We iterate two more time on the initial box blur
    
    if(uv.x < 1.0 && uv.y > 1.0) // Top-left quadrant
    {
    	return noBlur;
    }
    else if(uv.x > 1.0 && uv.y > 1.0) // Top-right quadrant
    {
    	return blur1;
    }
    else if (uv.x < 1.0 && uv.y < 1.0) // Bottom-left quadrant
    {
    	return blur2;
    }
    else // Bottom-right quadrant
    {
    	return blur3;
    }
}
