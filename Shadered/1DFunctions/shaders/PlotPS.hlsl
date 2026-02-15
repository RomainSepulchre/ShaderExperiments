cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

const float PI = 3.141592653589793;

uniform float plotThickness = 0.02;

uniform float plotExponent = 5.0;

uniform float stepValue = 0.5;

uniform float smoothstepValue = 0.1;

uniform float3 mirrorStEnTh; // x=start, y=end, z=thickness

uniform float moduloDivisor = 0.5;

// -----------------
// --- Functions ---
// -----------------

float plotLine(float2 uv, float pct)
{
	return smoothstep(pct - plotThickness, pct, uv.y) - 
			smoothstep(pct, pct + plotThickness, uv.y);
}


float4 drawPlot(float plot, float value, float3 lineColor = float3(1.0,1.0,0.0))
{
    float3 color = value;
    
    float plotLine = plot;   
    float3 background = (1.0 - plotLine) * color;
    float3 curve = plotLine * lineColor;
    color = background + curve;
    
    return float4(color,1.0);
}


// ****************
// ***** Main *****
// ****************

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    
    // linear
    float y = uv.x;
    
    // Exponential
    y = pow(uv.x, plotExponent);
    
    // Step
    y = step(stepValue, uv.x);
    
    // Smoothstep
    y = smoothstep(0 + smoothstepValue, 1 - smoothstepValue, uv.x);
    
    // Mirror smoothstep
    // mirrorStEnTh: x=start, y=end, z=thickness
    y = smoothstep(mirrorStEnTh.x - mirrorStEnTh.z, mirrorStEnTh.x + mirrorStEnTh.z,uv.x)
    	- smoothstep(mirrorStEnTh.y - mirrorStEnTh.z,mirrorStEnTh.y + mirrorStEnTh.z,uv.x);
    	
    // Sine
    y = (sin(uv.x * PI + uTime) + 1) / 2; // +1/2 to remap from [-1,1] to [0,1]
    
    // Cosine
    y = (cos(uv.x * PI + uTime) + 1) / 2; // +1/2 to remap from [-1,1] to [0,1]
    
    // Bouncing Sine
    y = abs(sin(uv.x * PI + uTime));
    
    // Frac() of a sine
    y = frac(sin(uv.x * PI + uTime));
    
    // Ceil() of a sine (Waves of 0 and 1)
    y = ceil(sin(uv.x * PI + uTime)); 
    
    // Floor() of a sine (Waves of 0 and -1)
    //y = floor(sin(uv.x * PI + uTime));
    
    // Modulo
    y = fmod(uv.x,moduloDivisor);   
    
    float plot = plotLine(uv, y);
    return drawPlot(plot, y);
}

