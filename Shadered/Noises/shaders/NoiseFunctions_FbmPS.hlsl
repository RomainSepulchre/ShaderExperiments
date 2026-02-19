cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;	
};

uniform float fbmGridLength;

uniform float fbmAmplitude;
uniform int fbmOctaves;

float2 randomVector2(float2 p, float time=0)
{
	p = p + 0.1;
	float x = dot(p, float2(123.4, 234.5));
	float y = dot(p, float2(234.5, 345.6));
	
	float2 vec2 = float2(x,y);
	vec2 = sin(vec2);
	vec2 = (vec2 * 43758.5453);
	
	vec2 = sin(vec2 + time);
	
	return vec2;
}

float2 cubic(float2 p)
{
    return p * p * (3.0 - p * 2.0);
}

float2 quintic(float2 p)
{
    return p * p * p * (10.0 + p * (-15.0 + p * 6.0));
}

float perlinNoise(float2 uv, float time=0)
{
	float2 gridId = floor(uv);
    float2 gridUV = frac(uv);
    
    float2 bottomLeft = gridId + float2(0.0, 0.0);
    float2 bottomRight = gridId + float2(1.0, 0.0);
    float2 topLeft = gridId + float2(0.0, 1.0);
    float2 topRight = gridId + float2(1.0, 1.0);
    
    float2 gradientBotL = randomVector2(bottomLeft, time);
    float2 gradientBotR = randomVector2(bottomRight, time);
    float2 gradientTopL = randomVector2(topLeft, time);
    float2 gradientTopR = randomVector2(topRight, time);
    
    gridUV = quintic(gridUV);
    
    float2 distPixelToBotL = gridUV - float2(0.0, 0.0);
    float2 distPixelToBotR = gridUV - float2(1.0, 0.0);
    float2 distPixelToTopL = gridUV - float2(0.0, 1.0);
    float2 distPixelToTopR = gridUV - float2(1.0, 1.0);
    
    float dotBotL = dot(gradientBotL, distPixelToBotL);
    float dotBotR = dot(gradientBotR, distPixelToBotR);
    float dotTopL = dot(gradientTopL, distPixelToTopL);
    float dotTopR = dot(gradientTopR, distPixelToTopR);
    
    float bottom = lerp(dotBotL, dotBotR, gridUV.x);
    float top = lerp(dotTopL, dotTopR, gridUV.x);
    float perlin = lerp(bottom, top, gridUV.y);
    
//    if(useBillowNoise) color = abs(perlin);
//    
//    if(useRidgedNoise)
//    {
//    	float ridgedNoise = 1.0 - abs(perlin);
//    	ridgedNoise = ridgedNoise * ridgedNoise;
//    	color = ridgedNoise;
//    }
    
  return perlin;
}

float fbmPerlinNoise(float2 uv, float amplitude = 1.0, int octaves = 1.0, float time=0)
{
    float fbmNoise = 0.0;
    for (int i=0; i < octaves; i++)
    {
        fbmNoise = fbmNoise + perlinNoise(uv, time) * amplitude;
        amplitude = amplitude * 0.5;
        uv = uv * 2.0;
    }

    return fbmNoise;
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    uv = uv * fbmGridLength;
    float3 color = 0;

    float fbmPerlin = fbmPerlinNoise(uv, fbmAmplitude, fbmOctaves, uTime);
    color = fbmPerlin + 0.1; // +0.1 to make it brighter

    
  
    return float4(color, 1);
}