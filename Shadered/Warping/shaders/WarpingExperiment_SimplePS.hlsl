cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform float uvScale;
uniform float noiseAmplitude;
uniform int noiseOctaves;
uniform int warpCount;
uniform float4 offsets;
uniform float3 colorA;
uniform float3 colorB;
uniform float3 colorC;


float2 quintic(float2 p)
{
    return p * p * p * (10.0 + p * (-15.0 + p * 6.0));
}

float whiteNoise2x1(float2 p)
{

    float random = dot(p, float2(12, 78));
    random = sin(random);
  	random = random * 43758.5453;
  	random = frac(random);
  	return random;
}

float sinNoise(float2 pos)
{
	return sin(pos.x) * sin(pos.y);
}

float valueNoise(float2 uv)
{

	float2 gridUV = frac(uv);
	float2 gridId = floor(uv);
	
    // Use quintic to smooth the noise
	gridUV =  quintic(gridUV);

    float botLeft = whiteNoise2x1(gridId);
    float botRight = whiteNoise2x1(gridId + float2(1.0, 0.0));
    float bottom = lerp(botLeft, botRight, gridUV.x);
    
    float topLeft = whiteNoise2x1(gridId + float2(0.0, 1.0));
    float topRight = whiteNoise2x1(gridId + float2(1.0, 1.0));
    float top = lerp(topLeft, topRight, gridUV.x);
    
    float vNoise = lerp(bottom, top, gridUV.y);
    
    return vNoise;
}

// Value noise function with integrated FBM
float valueNoise(float2 uv, float amplitude, int octaves) 
{
		float cells = uvScale;
		
		float vNoise = 0.0;
		for(int i = 0; i <= octaves; i++)
		{
			float2 gridUV = frac(uv * cells);
			float2 gridId = floor(uv * cells);
			
			// Use quintic to smooth the noise
			gridUV =  quintic(gridUV);
			
			float botLeft = whiteNoise2x1(gridId);
    		float botRight = whiteNoise2x1(gridId + float2(1.0, 0.0));
    		float bottom = lerp(botLeft, botRight, gridUV.x);
    
    		float topLeft = whiteNoise2x1(gridId + float2(0.0, 1.0));
    		float topRight = whiteNoise2x1(gridId + float2(1.0, 1.0));
    		float top = lerp(topLeft, topRight, gridUV.x);
	
			vNoise += lerp(bottom, top, gridUV.y) * amplitude;
			
			cells *= 2;
			amplitude *= 0.5;
			
		}
		vNoise /= 2.0; // divide by 2 to prevent bright noise value
    
    return vNoise;
}

float fbmSinNoise(float2 uv, float amplitude = 1.0, int octaves = 1.0)
{
    float fbm = 0.0;
    for (int i=0; i < octaves; i++)
    {
        fbm = fbm + sinNoise(uv) * amplitude;
        amplitude = amplitude * 0.5;
        uv = uv * 2.0;
    }

    return fbm;
}

float fbmValueNoise(float2 uv, float amplitude = 1.0, int octaves = 1.0)
{
    float fbm = 0.0;
    for (int i=0; i < octaves; i++)
    {
        fbm = fbm + valueNoise(uv) * amplitude;
        amplitude = amplitude * 0.5;
        uv = uv * 2.0;
    }

    return fbm;
}

float domainWarpNoise(float2 uv, float amplitude, int octaves)
{
	float fbm1 = valueNoise(uv + float2(0.0, 0.0), amplitude, octaves);
	float fbm2 = valueNoise(uv + float2(5.2, 1.3), amplitude, octaves);
	
	// second layer
	float fbm3 = valueNoise(uv + 4.0 * fbm1 + float2(1.7, 9.2), amplitude, octaves);
	float fbm4 = valueNoise(uv + 4.0 * fbm2 + float2(8.3, 2.8), amplitude, octaves);
	
	// third layer
	float fbm5 = valueNoise(uv + 8.0 * fbm3 + float2(6.1, 5.9), amplitude, octaves);
	float fbm6 = valueNoise(uv + 8.0 * fbm4 + float2(1.3, 4.4), amplitude, octaves);
	
	return valueNoise(float2(fbm3, fbm4), amplitude, octaves);
}

float domainWarpNoise(float2 uv, int count, float amplitude, int octaves)
{
	float scale = uvScale;
	float time = uTime / 100;
	float fbmX = valueNoise(uv + offsets.xy, amplitude, octaves);
	float fbmY = valueNoise(uv + offsets.zw, amplitude, octaves);
	
	for(int i = 0; i < count; i++)
	{
		fbmX = valueNoise(uv + scale * fbmX, amplitude, octaves);
		fbmY = valueNoise(uv + scale * fbmY, amplitude, octaves);
		
		scale *= 2;
	}
	
	return valueNoise(float2(fbmX,fbmY), amplitude, octaves);
}

float domainWarpNoise(float2 uv, int count, float amplitude, int octaves, out float2 a, out float2 b)
{
	float scale = uvScale;
	float time = uTime / 100;
	float fbmX = valueNoise(uv + offsets.xy, amplitude, octaves);
	float fbmY = valueNoise(uv + offsets.zw, amplitude, octaves);
	
	a.x = fbmX;
	a.y = fbmY;
	
	for(int i = 0; i < count; i++)
	{
		fbmX = valueNoise(uv + scale * fbmX, amplitude, octaves);
		fbmY = valueNoise(uv + scale * fbmY, amplitude, octaves);
		
		scale *= 2;
	}
	
	b.x = fbmX;
	b.y = fbmY;
	return valueNoise(float2(fbmX,fbmY), amplitude, octaves);
}


float warp1DValueNoise(float2 uv, float amplitude, int octaves)
{
	// f(p) = fbm( p + fbm( p + fbm( p )) )
	float fbm1 = valueNoise(uv, amplitude, octaves);
	float fbm2 = valueNoise(uv + fbm1, amplitude, octaves);
	float fbm3 = valueNoise(uv + fbm2, amplitude, octaves);
	
	return fbm3;
}

float warp1DValueNoise(float2 uv, float count, float amplitude, int octaves)
{
	float w = valueNoise(uv, amplitude, octaves);
	
	for(int i = 0; i < count; i++)
	{
		w = valueNoise(uv + w, amplitude, octaves);
	}
	
	return w;
}

float warpSinNoise(float2 uv, float count, float amplitude, int octaves)
{
	float w = fbmSinNoise(uv, amplitude, octaves);
	
	for(int i = 0; i < count; i++)
	{
		w = fbmSinNoise(uv + w, amplitude, octaves);
	}
	
	return w;
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    //float2 uv = (2.0 * fragCoord.xy - uResolution.xy) / uResolution.y; // scale with width
    float2 uv = fragCoord.xy/uResolution; // uniform scaling
    uv = uv * uvScale;
    
    float2 a;
    float2 b;
    float warpNoise = domainWarpNoise(uv, warpCount, noiseAmplitude, noiseOctaves, a, b);
    
    float3 color = lerp(colorA, colorB, warpNoise);
    
    return float4(color, 1.0f);
}
