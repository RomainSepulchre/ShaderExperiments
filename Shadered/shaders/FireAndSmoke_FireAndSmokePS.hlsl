// Based on https://www.shadertoy.com/view/33scR2

cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform float4 dbg;

float4 smoke(float2 uv)
{
    float depth, s;
    float t = uTime;
    
    float3 viewRes = float3(uResolution, 0.0);
    
    float4 colorOut = float4(0);
     
    for(float i = 0; i < 64.0; i ++,
    	viewRes.y *= 0.6, // Reduce viewRes to change the scale at each new loop
    	s = 0.3 + 0.2 * abs(viewRes.y - 2.0), // absolute dist of viewRes.y compared to 2.0, value is remaped to 0.3 + 20% of the absolute dist
    	depth += s, // accumulate s at each new iteration (store total of all s distance calculated) 
    	colorOut += 10.0 / s)
    {   
    	float j;
    	viewRes = float3(uv * depth, depth - t * 10.0); // Reset viewRes to be the to get new value based on the uv position and depth
    	for(j = .01; j < 4.; j += j)
    	{
    		// Deform viewRes value
    		viewRes.yz -= cos(viewRes.zx * 0.05); // Create periodic ondulations
    		float3 vecA = sin(0.02 * viewRes.z * j + 0.03 * viewRes.x + t + 0.5 * viewRes / j); // 0.02, 0.03 and 0.5 controls the smoke deformations
    		float3 vecB = float3(0.1 + j); // 0.1 control how much the smoke is stretch on Y axis
          	viewRes.yz -= abs(dot(vecA, vecB)); // Non-linear deformation the depends on j value
    	}
    }
    
    // divide by 2e3 to normalize over-saturated values and get a visible smoke effect
    return colorOut / 2000.0; 
}

float4 fire(float2 u)
{
    float i, d, s, n;
    float t = uTime;
    float3 p;
    float4 o = float4(0);
    float2x2 r = float2x2(cos(.3*t+float4(0,33,11,0)));
    
    for(; i++<64.; ) {
        p = float3(u * d, d);
        p += cos(p.z+t+p.yzx*.5)*.6;
        s = p.y-2.;
        p.yz *= r;
        for (n = 1.6; n < 32.; n += n )
            s += abs(dot(sin( p.z + t + p*n ), float3(2.5))) / n;
        d += s = .01 + abs(s)*.1;
        o += 1. / s;
    }
    
    return float4(6,2,1,1) * o * o / d / 2e5;
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{

    float2 uv = (fragCoord.xy - uResolution.xy / 2.0) / uResolution.y;
    
    float4 color = lerp(fire(uv), smoke(uv), 0.92);
	color = tanh(color); // tanh ?????
	
	color = smoke(uv);
    
    return color;
}
