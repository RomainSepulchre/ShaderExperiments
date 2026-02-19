cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
	
};

uniform float gridLength;
uniform int showDebugVector;
uniform int smoothUV;
uniform int animate;
uniform int useBillowNoise;
uniform int useRidgedNoise;

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

float sdfCircle(in float2 pos, in float radius)
{
	return length(pos) - radius;
}

float sdfOrientedBox(in float2 pos, in float2 a, in float2 b, float thickness)
{
  	float l = length(b - a);
  	float2 d = (b - a) / l;
  	float2 q = (pos - (a + b) * 0.5);
  	q = float2x2(d.x, -d.y, d.y, d.x) * q;
  	q = abs(q) - float2(l, thickness) * 0.5;
  	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

float2 cubic(float2 p)
{
  return p * p * (3.0 - p * 2.0);
}

float2 quintic(float2 p)
{
  return p * p * p * (10.0 + p * (-15.0 + p * 6.0));
}


float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    float3 color = 0;
    
    // Steps to create value noise:
    // 1. Create a grid of cells
    // 2. Create a random vector for every corner of the grid cells
    // 3. Find 4 vectors from corner pixel to current pixel and calculate dot product between them and the random vector
    // 4. Interpolate between the dot products to get a pixel color
    // 5. Smooth gridUV to hide grid edge
    
    // 1: Setup grid cells
    uv = uv * gridLength;
    float2 gridId = floor(uv);
    float2 gridUV = frac(uv);
    
    color = float3(gridUV, 0);
    
    // 2.1: Find coordinates of each grid corner
    float2 bottomLeft = gridId + float2(0.0, 0.0);
    float2 bottomRight = gridId + float2(1.0, 0.0);
    float2 topLeft = gridId + float2(0.0, 1.0);
    float2 topRight = gridId + float2(1.0, 1.0);
    
    // 2.2: Create a random gradient from each corner
    float time = animate ? uTime : 0.0;
    float2 gradientBotL = randomVector2(bottomLeft, time);
    float2 gradientBotR = randomVector2(bottomRight, time);
    float2 gradientTopL = randomVector2(topLeft, time);
    float2 gradientTopR = randomVector2(topRight, time);
    
    // Debug: visualize gradients vectors
    float2 gridCell = gridId + gridUV;
    float distG1 = sdfOrientedBox(gridCell, bottomLeft, bottomLeft + gradientBotL / 2.0, 0.015);
    float distG2 = sdfOrientedBox(gridCell, bottomRight, bottomRight + gradientBotR / 2.0, 0.015);
    float distG3 = sdfOrientedBox(gridCell, topLeft, topLeft + gradientTopL / 2.0, 0.015);
    float distG4 = sdfOrientedBox(gridCell, topRight, topRight + gradientTopR / 2.0, 0.015);

    
    // Debug: vizualise center of each grid cell
    float circleRadius = 0.015;
    float2 circleCenter = float2(0.5, 0.5);
    float distToCircle = sdfCircle(gridUV - circleCenter, circleRadius);

    
    // 5: Smooth grid uv
    if(smoothUV)
    {
    	//gridUV = smoothstep(0.0,1.0,gridUV);
    	//gridUV = cubic(gridUV);
    	gridUV = quintic(gridUV);
    }
    
    
    // 3.1: Find distance between current pixel and each grid corner
    float2 distPixelToBotL = gridUV - float2(0.0, 0.0);
    float2 distPixelToBotR = gridUV - float2(1.0, 0.0);
    float2 distPixelToTopL = gridUV - float2(0.0, 1.0);
    float2 distPixelToTopR = gridUV - float2(1.0, 1.0);
    
    // 3.2: calculate dot product between gradients and pixel distance
    float dotBotL = dot(gradientBotL, distPixelToBotL);
    float dotBotR = dot(gradientBotR, distPixelToBotR);
    float dotTopL = dot(gradientTopL, distPixelToTopL);
    float dotTopR = dot(gradientTopR, distPixelToTopR);
    
    // 4: Interpolate between the dot products
    float bottom = lerp(dotBotL, dotBotR, gridUV.x);
    float top = lerp(dotTopL, dotTopR, gridUV.x);
    float perlin = lerp(bottom, top, gridUV.y);
    color = perlin + 0.1; // +0.1 to make it brighter
    
    if(useBillowNoise) color = abs(perlin);
    
    if(useRidgedNoise)
    {
    	float ridgedNoise = 1.0 - abs(perlin);
    	ridgedNoise = ridgedNoise * ridgedNoise;
    	color = ridgedNoise;
    }
    
    
    if(showDebugVector)
    {
    	float3 debugColor = float3(1.0, 0.0, 1.0);
	    if(distG1 < 0.0 || distG2 < 0.0 || distG3 < 0.0 || distG4 < 0.0) color = debugColor;
	    color = distToCircle > 0.0 ? color : debugColor;    
    }
    
    return float4(color, 1);
}