// empty shader file
cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;	
};

uniform float normGridLength;

uniform float normAmplitude;
uniform int normOctaves;

uniform float3 normLightColor;
uniform float normSpecularIntensity;

uniform int normShowNormals;
uniform int normShowOnlyDiffuse;
uniform int normShowOnlySpecular;

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

float domainWarpPerlinNoise(float2 uv)
{
	float fbm1 = fbmPerlinNoise(uv + float2(0.0, 0.0), normAmplitude, normOctaves, uTime);
	float fbm2 = fbmPerlinNoise(uv + float2(5.2, 1.3), normAmplitude, normOctaves, uTime);
	
	// second layer
	float fbm3 = fbmPerlinNoise(uv + 4.0 * fbm1 + float2(1.7, 9.2), normAmplitude, normOctaves, uTime);
	float fbm4 = fbmPerlinNoise(uv + 4.0 * fbm2 + float2(8.3, 2.8), normAmplitude, normOctaves, uTime);
	
	// third layer
	float fbm5 = fbmPerlinNoise(uv + 8.0 * fbm3 + float2(6.1, 5.9), normAmplitude, normOctaves, uTime);
	float fbm6 = fbmPerlinNoise(uv + 8.0 * fbm4 + float2(1.3, 4.4), normAmplitude, normOctaves, uTime);
	
	return fbmPerlinNoise(float2(fbm1, fbm2), normAmplitude, normOctaves, uTime);
}

float3 calculateNormal(float2 uv)
{
	float diff = 0.001;
	float p1 = domainWarpPerlinNoise(uv + float2(diff, 0.0));
	float p2 = domainWarpPerlinNoise(uv - float2(diff, 0.0));
	float p3 = domainWarpPerlinNoise(uv + float2(0.0, diff));
	float p4 = domainWarpPerlinNoise(uv - float2(0.0, diff));
	
	float3 normal = normalize(float3(p1 - p2, p3 - p4, 0.001));
	
	return normal;
}

float3 diffuseLighting(float3 normal, float3 lightSource, float3 lightColor = 1.0)
{    
    float diffuseStrength = max(0.0, dot(normal, lightSource));
    float3 diffuse = diffuseStrength * lightColor;
    float3 lighting = diffuse * 0.5;
    
    return lighting;
}

float3 specularLighting(float3 normal, float3 lightSource, float3 lightColor = 1.0)
{
	float3 cameraSource = float3(0.0, 0.0, 1.0);
    float3 viewSource = normalize(cameraSource);
    float3 reflectSource = normalize(reflect(-lightSource, normal));
    float specularStrength = max(0.0, dot(viewSource, reflectSource));
    specularStrength = pow(specularStrength, normSpecularIntensity);
    float3 specular = specularStrength * lightColor; 
    
    return specular;
}

float3 diffuseSpecularLighting(float3 normal, float3 lightSource, float3 lightColor = 1.0)
{
	float3 diffuse = diffuseLighting(normal, lightSource, lightColor);
	float3 specular = specularLighting(normal, lightSource, lightColor);
	
	return diffuse * 0.5 + specular * 0.5;
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    uv = uv * normGridLength;
    float3 color = 0;
    
    float3 normal = calculateNormal(uv);
    float3 lightSource = 1.0;
    
    if(normShowNormals)
    {
    	color = normal;
    }
    else if(normShowOnlyDiffuse)
    {
    	color = diffuseLighting(normal, lightSource, normLightColor);
    }
    else if(normShowOnlySpecular)
    {
    	color = specularLighting(normal, lightSource, normLightColor);
    }
    else // Full lighting
    {
    	color = diffuseSpecularLighting(normal, lightSource, normLightColor);
    }    
  
    return float4(color, 1);
}