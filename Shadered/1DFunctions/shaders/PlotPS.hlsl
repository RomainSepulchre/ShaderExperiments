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

// Draw functions
// ..............

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

// plot functions
// ..............

float impulse(float k, float x)
{
    float h = k * x;
    return h * exp(1.0 - h);
}

float cubicPulse(float c, float w, float x)
{
    x = abs(x - c);
    if(x > w) return 0.0;
    x /= w;
    return 1.0 - x * x * (3.0  - 2.0 * x);
}

float expStep(float k, float n, float x)
{
    return exp( -k * pow(x,n));
}

float parabola(float k, float x)
{
    return pow(4.0 * x * (1.0 - x), k);
}

float pcurve(float a, float b, float x)
{
    float k = pow(a + b, a + b) / (pow(a,a) * pow(b,b));
    return k * pow(x, a) * pow(1.0 - x, b);
}

float quadraticBezier(float2 a, float x)
{
  	float epsilon = 0.00001;
  	a.x = clamp(a.x, 0.0, 1.0); 
  	a.y = clamp(a.y, 0.0, 1.0); 
  	if (a.x == 0.5) a += epsilon;
  	
  	// solve t from x (an inverse operation)
  	float om2a = 1.0 - 2.0 * a.x;
 	float t = (sqrt(a.x * a.x + om2a * x) - a.x) / om2a;
  	float y = (1.0 - 2.0 * a.y) * (t * t) + (2.0 * a.y) * t;
  	
  	return y;
}

// Cubic bezier
// https://thebookofshaders.com/edit.php?log=160414041933

// Cubic bezier through 2 points
// https://thebookofshaders.com/edit.php?log=160414041756

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
    
    // Impulse
    y = impulse(9 + sin(uTime) * 2, uv.x);
    
    // Cubic pulse
    y = cubicPulse(0.5 + sin(uTime) / 6, 0.2 + cos(uTime) / 10, uv.x);
    
    // Exponential Step
    y = expStep(10 + sin(uTime) * 4,2 + cos(uTime), uv.x);
    
    // Parabola
    y = parabola( 2 + sin(uTime) * 1.5, uv.x);
    
    // PCurve
    y = pcurve(1 + sin(uTime), 1 + cos(uTime), uv.x);
    
    // Quadratic Bezier
    float2 qBezier = float2(cos(uTime), sin(uTime)) * 0.45 + 0.5;
    y = quadraticBezier(qBezier, uv.x);
    
    // Cubic bezier
    
    float plot = plotLine(uv, y);
    return drawPlot(plot, y);
}

