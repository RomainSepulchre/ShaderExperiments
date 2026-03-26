// Based on https://www.shadertoy.com/view/33scR2

cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform float4 dbg;

float4 smoke(float2 uv)
{
    float depth, offset;
    float t = uTime;
    
    float3 smokeUv = float3(uResolution, 0.0);
    
    float4 colorOut = float4(0);
     
    for(float i = 0; i < 64.0; i ++, // each new iteration add new density layer to the smoke
    	smokeUv.y *= 0.6, // Reduce smokeUv to change the scale at each new loop
    	offset = 0.3 + 0.2 * abs(smokeUv.y - 2.0), // absolute dist of smokeUv.y compared to 2.0, value is remaped to 0.3 + 20% of the absolute dist
    	depth += offset, // accumulate offset at each new iteration (store total of all offset distance calculated) 
    	colorOut += 10.0 / offset)
    {   
    	float j;
    	smokeUv = float3(uv * depth, depth - t * 10.0); // Reset smokeUv to be the to get new value based on the current depth
    	for(j = 0.01; j < 4.0; j += j)
    	{
    		// Deform smokeUv value
    		smokeUv.yz -= cos(smokeUv.zx * 0.05); // Create periodic ondulations
    		float3 vecA = sin(0.02 * smokeUv.z * j + 0.03 * smokeUv.x + t + 0.5 * smokeUv / j); // 0.02, 0.03 and 0.5 controls the smoke deformations
    		float3 vecB = float3(0.1 + j); // 0.1 control how much the smoke is stretch on Y axis
          	smokeUv.yz -= abs(dot(vecA, vecB)); // Non-linear deformation that depends on j value
    	}
    }
    
    // divide by 2e3 to normalize over-saturated values and get a visible smoke effect
    return colorOut / 2000.0; 
}

float4 fire(float2 uv)
{
    float depth, offset;
    float t = uTime;
    
    float3 fireUv;
    
    float4 colorOut = float4(0);
    float2x2 rotMatrix = float2x2(cos(0.3 * t + float4(0, 33, 11, 0)));
    
    for(float i=0; i < 64.0; i++) // each new iteration add new density layer to the fire
    {
        fireUv = float3(uv * depth, depth); // Reset fireUv to get new value based on the current depth
        fireUv += cos(fireUv.z + t + fireUv.yzx * 0.5) * 0.6; // Add a periodic deformation of the UV to create ondulation
        offset = fireUv.y - 2.0; // dist of fireUv.y compared to 2.0
        fireUv.yz *= rotMatrix; // Apply the rotation matrix to simulate a swirling fire
        
        for (float j = 1.6; j < 32.0; j += j)
        {
        	// Deform offset value: Non-linear deformation that depends on j value
        	offset += abs(dot(sin(fireUv.z + t + fireUv * j), float3(2.5))) / j;
        }
        
        offset = 0.01 + abs(offset) * 0.1; // Get the absolute value of the offset and reduce it
        depth += offset; // accumulate offset at each new iteration (store total of all offset distance calculated) 
        colorOut += 1.0 / offset;
    }
    
    float4 fireColor = float4(6,2,1,1);
    
    // Return final color
    // -> Apply fire color
    // -> colorOut * colorOut: to accentuate bright spot of the fire (we could multiply by a huge value like 1e3 to have more neutral color)
    // -> we divide by depth to equlibrate the intensity then by 2e5 to normalize the color value
    return fireColor * colorOut * colorOut / depth / 2e5;
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{

    float2 uv = (fragCoord.xy - uResolution.xy / 2.0) / uResolution.y;
    
    float4 color = lerp(fire(uv), smoke(uv), 0.92);
    // tanh = hyperbolic tangent of a value
    // -> we use tanh() to bring back the colors in a more standard interval
    // 		-> Reduce high value and overexposed zone, increase shadows and keep details in the medium value
	color = tanh(color);
	
	color = lerp(fire(uv), 0.0, 0.92);
    
    return color;
}
