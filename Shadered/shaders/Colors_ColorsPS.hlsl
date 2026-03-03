cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

const float PI = 3.1415927;

uniform float3 colorA;
uniform float3 colorB;

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

float easeInOutElastic(float x)
{
	const float c5 = (2 * PI) / 4.5;

	return x == 0 ? 0 : x == 1
  				   ? 1 : x < 0.5
  				   ? -(pow(2, 20 * x - 10) * sin((20 * x - 11.125) * c5)) / 2
  					: (pow(2, -20 * x + 10) * sin((20 * x - 11.125) * c5)) / 2 + 1;
}

float plotLine(float2 uv, float pct)
{
	return smoothstep(pct - 0.02, pct, uv.y) - 
			smoothstep(pct, pct + 0.02, uv.y);
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    
    float3 color;
    
    float2 qBezier = float2(cos(uTime), sin(uTime)) * 0.45 + 0.5;
    float t = quadraticBezier(qBezier, abs(sin(uTime)));
    
    t = easeInOutElastic(abs(sin(uTime)));
    
    float plot = plotLine(uv, t);
    
    color = lerp(colorA, colorB, t);
    
    color += plot;
    
    return float4(color, 1.0f);
}
