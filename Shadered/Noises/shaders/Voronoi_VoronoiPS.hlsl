cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
	
};

uniform float gridLength;
uniform int showGridOutline;
uniform float gridOutlineThickness;
uniform int onlyPoints;
uniform float pointSize;
uniform int onlyClosestPointDist;
uniform int offsetPoints;
uniform float2 offsetIntensity;
uniform int AnimatePoints;
uniform int cloudVoronoi;


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
    
    // Steps to create voronoi noise:
    // 1. Create a grid of cells and define a point at the center
    // 2. Iterate through pixels and find minimum distance with closest point
    // 3. Use noise to offset the points and generate a more organic result
    
    // 1.1: Setup the grid
    uv = uv * gridLength;
    
    if(!offsetPoints && AnimatePoints) uv += uTime; // Simple scroll animation when points are not offset
    
    float2 gridId = floor(uv);
    float2 gridCoord = frac(uv);
    
    gridCoord = gridCoord - 0.5; // Center grid coordinates to place them at the center of the cell
	
	// 1.2: Create cell edges and get their distance
	float2 gridCell = abs(gridCoord);
	float distToCellEdge = 2.0 * max(gridCell.x, gridCell.y);
	
	float outlineMin = (1.0 - gridOutlineThickness) - 0.01; // 0.01 tells smooth intensity
	float outlineMax = (1.0 - gridOutlineThickness) + 0.01; // 0.01 tells smooth intensity
	float gridOutline = smoothstep(outlineMin, outlineMax, distToCellEdge);
	
	// 2: Iterate through each pixels and find minimum distance to closest points
	float pointsOnGrid = 0.0;
	float minDistFromPixel = 100.0;
	
	// 2.1: Iterate around a uv position (here: gridCoord) 
	for (float i = -1.0; i <= 1.0; i++)
	{
		for (float j = -1.0; j <= 1.0; j++)
		{
			float2 adjGridCoords = float2(i,j);
			
			float2 pointOnAdjGrid = adjGridCoords;
			
			// 3: Offset points position with a noise
			float2 pointPosNoise = noise2x2(gridId + adjGridCoords);
			if(offsetPoints && !AnimatePoints) // Offset only
			{
				pointOnAdjGrid = adjGridCoords + pointPosNoise * offsetIntensity; 
			}
			else if(offsetPoints && AnimatePoints) // Offset and animate
			{
				pointOnAdjGrid = adjGridCoords + sin(uTime * pointPosNoise) * offsetIntensity; 
			}
			
			// 2.2: Calculate distance from points position to get min distance and draw points
			float dist = length(gridCoord - pointOnAdjGrid); // Calculate 
			
			// 2.3: Get value to draw minimum distance to closest point
			minDistFromPixel = min(dist, minDistFromPixel);
			
			// 2.3: Get value to draw points
			float pointMinSize = (1.0 - pointSize) - 0.005; // 0.005 tells smooth intensity
			float pointMaxSize = (1.0 - pointSize) + 0.005; // 0.005 tells smooth intensity
			pointsOnGrid += smoothstep(pointMinSize, pointMaxSize, 1.0 - dist); // 1.0 - dist to invert circle mask
		}
	}
	
	if(onlyPoints) color = float4(pointsOnGrid.xxx,1);
	else if (onlyClosestPointDist) color = float4(minDistFromPixel.xxx,1);
	else
	{
		if(cloudVoronoi)
		{
			//color = smoothstep(0.0, 1.0,  minDistFromPixel);
			color = smoothstep(0.0, 1.0,  1.0 - minDistFromPixel);
		}
		else
		{
			color = pointsOnGrid + minDistFromPixel;
		}
	}	
	
	if(showGridOutline) color.r = gridOutline;
	
	return float4(color,1);

}