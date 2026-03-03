cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

const float PI = 3.1415927;

uniform float uvScale;

uniform float3 colorC;
uniform float3 colorD;
uniform float3 colorE;


uniform float4 d;

float easeInOutElastic(float x)
{
	const float c5 = (2 * PI) / 4.5;

	return x == 0 ? 0 : x == 1
  				   ? 1 : x < 0.5
  				   ? -(pow(2, 20 * x - 10) * sin((20 * x - 11.125) * c5)) / 2
  					: (pow(2, -20 * x + 10) * sin((20 * x - 11.125) * c5)) / 2 + 1;
}

float easeInOutCubic(float x)
{
	return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2;
}

float plotLineY(float2 uv, float pct)
{
	return smoothstep(pct - 0.02, pct, uv.x) - 
			smoothstep(pct, pct + 0.02, uv.x);
}

float plotLineX(float2 uv, float pct)
{
	return smoothstep(pct - 0.02, pct, uv.y) - 
			smoothstep(pct, pct + 0.02, uv.y);
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = (fragCoord.xy/uResolution) * uvScale;
    uv.y += 0.25;
    
    float3 color;
    
    float3 t = uv.y;
    t = easeInOutCubic(uv.y);
    //float3 t = easeInOutElastic(uv.x);
    
    //t = smoothstep(0.0, 1.0, uv.y);
    //t = sin(uv.x * PI);
    //t = pow(uv.y, 0.5);
    
    //float plot = plotLine(uv, t);
    
    float3 botColor = colorD;
    float3 topColor = lerp(colorC, colorE, sin(uTime));
    
    // Main color mix
    color = lerp(botColor, topColor, t);
    
    // Draw plot line
    //color = lerp(color, float3(1.0, 0.0, 0.0), plotLineY(uv, t.r));
    //color = lerp(color, float3(0.0, 1.0, 0.0), plotLineY(uv, t.g));
    //color = lerp(color, float3(0.0, 0.0, 1.0), plotLineY(uv, t.b));
    
    // Flag
    color = float3(0.0, 0.0, 1.0) * step(uv.x, 0.33);
    color += step(uv.x, 0.66) - (step(uv.x, 0.33));
    color += float3(1.0, 0.0, 0.0) * (1 - step(uv.x, 0.66));
    
    // Rainbow   
    color = lerp(float3(0.0,0.0,1.0), float3(1.0,0.0,0.0), smoothstep(0.0, 1.0, uv.y));
    //color = lerp(color, float3(0.0,1.0,0.0), smoothstep(0.5, 1.0, uv.y));
    
    //color = smoothstep(d.x+d.y, d.x-d.y, uv.y);
    
    
    
    return float4(color, 1.0f);
}