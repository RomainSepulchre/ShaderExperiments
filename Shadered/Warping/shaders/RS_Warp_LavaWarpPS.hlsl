cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform int seed = 0;
uniform float uvScale = 1.0;
uniform float noiseExp = 8.0;
uniform float2x2 warpMatrix;
uniform int fbmOctaves;
uniform float4 fbm2Offset;

uniform float3 colorA, colorB, colorC, colorD, colorE;

float hash(float2 uv)
{
	uv += float(seed);
	return frac(sin(dot(uv.xy, float2(12.9898, 75.233))) * 43758.5453);
}

float valueNoise(float2 uv)
{
	uv *= 6.0;
	float2 gridId = floor(uv);
	float2 gridUv = frac(uv);
	
	gridUv = pow(gridUv, noiseExp); // Smooth/Sharpen noise
	//gridUv = gridUv * gridUv * (3.0 - 2.0 * gridUv);
	
	float botL = hash(gridId + float2(0, 0));
	float botR = hash(gridId + float2(1, 0));
	float topL = hash(gridId + float2(0, 1));
	float topR = hash(gridId + float2(1, 1));
	
	float bot = lerp(botL, botR, gridUv.x);
	float top = lerp(topL, topR, gridUv.x);
	
	float vNoise = lerp(bot, top, gridUv.y);
	
	return vNoise * vNoise * vNoise;

}

float fbmNoise(float2 uv, int octaves)
{
	float fbm = 0.0;
	
	float amplitude = 0.5;
	float totalAmplitude = 0.0;
	float scaleMultiplier = 2.0;
	
	for(int i = 0; i < octaves; i++)
	{
		fbm += valueNoise(uv) * amplitude;
		uv = warpMatrix * uv * scaleMultiplier;
		totalAmplitude += amplitude;
		amplitude *= 0.5;
	}
	
	return fbm / totalAmplitude;
}

float2 fbm2Noise(float2 uv, int octaves)
{
	float2 offsetX = float2(fbm2Offset.x, fbm2Offset.y);
	float2 offsetY = float2(fbm2Offset.z, fbm2Offset.w);
	
	return float2(fbmNoise(uv + offsetX, octaves), fbmNoise(uv + offsetY, octaves));
}


float warp(float2 uv, out float fbm1, out float2 fbm2, out float2 mask)
{
	// Ripple effect
	float rippleIntensity = 1.25;
    float2 rippleSpeed = float2(0.25, 0.55);
    float rippleScale = 6.0;
    uv += rippleIntensity * sin(rippleSpeed * uTime + length(uv) * rippleScale);
    
    fbm1 = fbmNoise(uv, fbmOctaves);
    
    uv += 0.25 * dot(fbm1, fbm1);
    
    fbm2 = fbm2Noise(uv, 8);
    
    uv = uv * 0.05 + fbm2 + 0.60;
    
    float warpNoise = 0.25 + 1.5 * fbmNoise(uv, 4.0);
    
    mask = warpNoise * uv;

	return warpNoise;
}


float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    //float2 uv = (fragCoord.xy / uResolution) * uvScale; // uniform scaling
    float2 uv = (uvScale * fragCoord.xy - uResolution.xy * (uvScale / 2)) / uResolution.y; // height scaling
    
    float3 color;
    
    float fbm1;
    float2 fbm2, mask;
    float warpNoise = warp(uv, fbm1, fbm2, mask);
	
	color = lerp(colorA, colorB, warpNoise);
	color = lerp(color, colorC,  fbm1);
	color += colorD * dot(fbm2.x, fbm2.y);
	color += colorE * (mask.x - mask.y);
	color *= 1.0 + abs(mask.x * mask.y);
	
	
	return float4(color, 1.0f);   
    
}
