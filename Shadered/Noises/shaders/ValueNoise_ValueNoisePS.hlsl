cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
	
};

uniform float cellCount;
uniform int showCells; // int used as bool
uniform int showGridId; // int used as bool
uniform int showSingleNoise; // int used as bool
uniform int smoothInterpolation;
uniform int showWhiteNoise;
uniform int noiseOctaves;


float whiteNoise2x1(float2 p)
{
	// Linear value 
	//return p.x;
	
	// Star pattern
	//return frac(p.x * p.y * 1000.0123);
	
	// Generic noise
	//float random = dot(p, float2(12.9898, 78.233));
    float random = dot(p, float2(12., 78.));
    random = sin(random);
  	random = random * 43758.5453;
  	random = frac(random);
  	return random;
}

float2 cubic(float2 p)
{
  	return p * p * (3.0 - 2.0 * p);
}

float2 quintic(float2 p)
{
  	return p * p * p * (10.0 + p * (-15.0 + p * 6.0));
}

float valueNoise(float2 uv)
{
	// -> All the steps detailed in main() regrouped in a dedicated function
	
	// 2.
	float2 gridUV = frac(uv);
	float2 gridId = floor(uv);
	
	// 4.
	if(smoothInterpolation)
	{
		//gridUV = smoothstep(0.0, 1.0, gridUV);
    	//gridUV = cubic(gridUV);
    	gridUV = quintic(gridUV);
	}
    
    // 3.
    float botLeft = whiteNoise2x1(gridId);
    float botRight = whiteNoise2x1(gridId + float2(1.0, 0.0));
    float bottom = lerp(botLeft, botRight, gridUV.x);
    
    float topLeft = whiteNoise2x1(gridId + float2(0.0, 1.0));
    float topRight = whiteNoise2x1(gridId + float2(1.0, 1.0));
    float top = lerp(topLeft, topRight, gridUV.x);
    
    float vNoise = lerp(bottom, top, gridUV.y);
    
    return vNoise;
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    float3 color = 0;
    
    uv.x += sin(uTime) * 0.05;
    uv.y += cos(uTime) * 0.05;
    
    // Steps to create value noise:
    // 1. Create white noise 
    // 2. Divide white noise in grid 
    // 3. Determine edges of the grid cells and perform bilinear interpolation
    // 4. Smooth noise result
    // 5. Add layers of noise
    
    // 1: Create a white noise
    color = whiteNoise2x1(uv);
    
    // 2.1: Divide white noise in grid
    uv = uv * cellCount;
    float2 gridUV = frac(uv); 
    
    
    // 2.2: Set grid Id
    float2 gridId = floor(uv);
    
    // 4: Smooth UV coordinates to remove rough edges
    if(smoothInterpolation)
    {
    	//gridUV = smoothstep(0.0, 1.0, gridUV);
    	//gridUV = cubic(gridUV);
    	gridUV = quintic(gridUV);
    }
    
    // 3: Bilinear interpolation between Bottom/Left-Bottom/Right and Top/Left-Top/Right corners
    float botLeft = whiteNoise2x1(gridId);
    float botRight = whiteNoise2x1(gridId + float2(1.0, 0.0));
    float bottom = lerp(botLeft, botRight, gridUV.x);
    
    float topLeft = whiteNoise2x1(gridId + float2(0.0, 1.0));
    float topRight = whiteNoise2x1(gridId + float2(1.0, 1.0));
    float top = lerp(topLeft, topRight, gridUV.x);
    
    float valNoise = lerp(bottom, top, gridUV.y);
    
    if(showSingleNoise) color = valNoise;
    //if(!showCells && !showGridId && !showInterpolation) color = valNoise;
    
    // 5: Add layers of noise
    // -> for each new layer we multiply the number of cells by 2 and we divide the intensity by 2
    
    // Ex:
	//	valNoise = valueNoise(uv * 4.0) * 1.0; // 4 cells, 1.0 (full intensity)
	//	valNoise += valueNoise(uv * 8.0) * 0.5; // 8 cells, 0.5 = (half intensity)   
	//	valNoise += valueNoise(uv * 16.0) * 0.25; // 16 cells, 0.25 = (quarter intensity)  
	//	valNoise += valueNoise(uv * 32.0) * 0.125; // ... and so on
	//	valNoise += valueNoise(uv * 64.0) * 0.0625;
	//  valNoise /= 2.0; // divide by 2 to prevent bright noise value
	
	if(!showSingleNoise && !showWhiteNoise)
	{
		float cells = cellCount;
		float intensity = 1.0;
		float noiseLayers = valueNoise(uv * cells) * intensity;
		for(int i = 1; i <= noiseOctaves; i++)
		{
			cells *= 2;
			intensity *= 0.5;
			noiseLayers += valueNoise(uv * cells) * intensity;
		}
		noiseLayers /= 2.0; // divide by 2 to prevent bright noise value
		
		color = noiseLayers;
	}
	
	if(showCells && !showGridId) color.rg += gridUV;
	if(showGridId) color.gb += gridId * 0.25;
    
    return float4(color, 1);
}