cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
	
};

uniform float gridLength;

float2 noise2x2(float2 p)
{
	float x = dot(p, float2(123.4, 234.5));
	float y = dot(p, float2(345.6, 456.7));
	float2 n = float2(x, y);
	n = sin(n);
	n = n * 43758.5453;
	n = frac(n);
	return n;
}


float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    float3 color = 0;
    
    //uv.x += sin(uTime) * 0.05;
    //uv.y += cos(uTime) * 0.05;
    
    // Steps to create value noise:
    // 1. Create a grid of cells with a point at the center
    // 2. Iterate through pixels and find minimum distance with closest point
    // 3. Use noise to offset the points and generate a more organic result
    // 4. 
    // 5.
    
    // 1: Setup the grid
    uv = uv * gridLength;
    
    float2 gridId = floor(uv);
    float2 gridCoord = frac(uv);
    
    gridCoord = gridCoord - 0.5; // Center grid coord

	// 1.2:
	float2 redGridUV = gridCoord;
	redGridUV = abs(redGridUV);
	
	float distToCellEdge = 2.0 * max(redGridUV.x, redGridUV.y);
	
	color = distToCellEdge;
	color = smoothstep(0.5, 1.0, distToCellEdge);
	float3 redGridColor = float3(smoothstep(0.9, 1.0, distToCellEdge), 0, 0); // Red grid outline
	
	// 2.1:
	float pointsOnGrid = 0.0;
	float minDistFromPixel = 100.0;
	
	for (float i = -1.0; i <= 1.0; i++)
	{
		for (float j = -1.0; j <= 1.0; j++)
		{
			float2 adjGridCoords = float2(i,j);
			float2 pointOnAdjGrid = adjGridCoords;
			//pointOnAdjGrid = adjGridCoords + sin(uTime) * 0.5;
			float2 pointNoise = noise2x2(gridId + adjGridCoords);
			pointOnAdjGrid = adjGridCoords + sin(uTime * pointNoise) * 0.5;
			
			float dist = length(gridCoord - pointOnAdjGrid);
			minDistFromPixel = min(dist, minDistFromPixel);
			
			pointsOnGrid += smoothstep(0.95, 0.96, 1.0 - dist);
		}
	}
	
	float3 pointsOngridColor = pointsOnGrid;
	color = redGridColor + pointsOngridColor;
	color = redGridColor + pointsOngridColor + minDistFromPixel;
	color = pointsOngridColor + minDistFromPixel;
	
	
	// cloud
	color = smoothstep(0.0, 1.0, minDistFromPixel);
	color = smoothstep(0.0, 1.0,  1.0 - minDistFromPixel);
	
	
    
    
    return float4(color, 1);
}