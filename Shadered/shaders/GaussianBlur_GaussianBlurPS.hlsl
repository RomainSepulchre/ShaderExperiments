cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform Texture2D uTexture : register(t0);
uniform SamplerState uSampler : register(s0);

uniform int useGaussian;
uniform int useBoxBlur;
uniform float uKernelSize;
uniform float resolutionDivisor;
uniform float4 d;

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
	//float2 uv = (fragCoord.xy - uResolution) / uResolution.y; // Height scaling
    float2 uv = fragCoord.xy/uResolution; // uniform scaling
    
    
    float4 texColor = uTexture.Sample(uSampler, uv);
    
    float3 color = texColor.rgb;
    
    float2 imgResolution = float2(512,512);
    imgResolution /= resolutionDivisor;//10.0;
    float texelSize = 1.0/imgResolution;
    
    // BOX BLUR
    const float kernelSize = uKernelSize; // Range of pixel that will be sampled around the pixel we want to blur
    
    float3 boxBlurColor = 0.0;
    float boxBlurDivisor = pow(2.0 * kernelSize + 1.0, 2.0);
    
    // Sample the color around the pixel
    for(float i=-kernelSize; i<=kernelSize; i++)
    {
    	for(float j=-kernelSize; j <=kernelSize; j++)
    	{
    		float4 blurTexColor = uTexture.Sample(uSampler, uv + float2(i,j) * texelSize);
    		boxBlurColor += blurTexColor.rgb;
    	}
    }
    
    // Get the average color of sampled pixels
    boxBlurColor /= boxBlurDivisor;
    
    // GAUSSIAN BLUR
    float gaussianDivisor = 16.0;
    float3 gaussianBlurColor = 0.0;
    
    // Sample the color around the pixel
    gaussianBlurColor += uTexture.Sample(uSampler, uv + float2(-1,1) * texelSize).rgb * 1.0;
    gaussianBlurColor += uTexture.Sample(uSampler, uv + float2(0,1) * texelSize).rgb * 2.0;
    gaussianBlurColor += uTexture.Sample(uSampler, uv + float2(1,1) * texelSize).rgb * 1.0;
    gaussianBlurColor += uTexture.Sample(uSampler, uv + float2(-1,0) * texelSize).rgb * 2.0;
    gaussianBlurColor += uTexture.Sample(uSampler, uv + float2(0,0) * texelSize).rgb * 4.0;
    gaussianBlurColor += uTexture.Sample(uSampler, uv + float2(1,0) * texelSize).rgb * 2.0;
    gaussianBlurColor += uTexture.Sample(uSampler, uv + float2(-1,-1) * texelSize).rgb * 1.0;
    gaussianBlurColor += uTexture.Sample(uSampler, uv + float2(0,-1) * texelSize).rgb * 2.0;
    gaussianBlurColor += uTexture.Sample(uSampler, uv + float2(1,-1) * texelSize).rgb * 1.0;
    
    // Get the average color of sampled pixels
    gaussianBlurColor /= gaussianDivisor;
    
    
    if(useGaussian || useBoxBlur)
    {
    	color =  useGaussian ? gaussianBlurColor : boxBlurColor;
    }
    else
    {
    	color = texColor;
    }
    
    return float4(color, 1.0f);
}
