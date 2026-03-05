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
    
    float3 color;
    
    float3 t = uv.y;
    //t = easeInOutCubic(uv.y);
    //t = easeInOutElastic(uv.x);
    //t = smoothstep(0.0, 1.0, uv.y);
    //t = sin(uv.x * PI);
    //t = pow(uv.y, 0.5);
    
    //float plot = plotLine(uv, t);
    
    // 4 way gradient
    float3 botLColor = float3(0.772, 0.337, 0.170);
    float3 botRColor = float3(0.857, 0.454, 0.073);
    float3 botGradient = lerp(botLColor, botRColor, uv.x);
    
    float3 topLColor = float3(0.274, 0.645, 0.923);
    float3 topRColor = float3(0.830, 0.616, 0.413);
    float3 topGradient = lerp(topLColor, topRColor, uv.x);
    
    color = lerp(botGradient, topGradient, uv.y);
    
    // Animated gradient
    //uv.y += 0.25; // Add small offset on the UV
    float3 sunriseBotCol = colorC;
    float3 sunriseTopCol = colorD;
    float3 sunriseCol = lerp(colorC, colorD, uv.y);
    
    float3 sunsetBotCol = colorE;
    float3 sunsetTopCol = float3(0.171, 0.098, 0.270);
    float3 sunsetCol = lerp(sunsetBotCol, sunsetTopCol, uv.y);
    
    color = lerp(sunriseCol, sunsetCol, abs(sin(uTime)));
    
    // Draw plot line
    //color = lerp(color, float3(1.0, 0.0, 0.0), plotLineY(uv, t.r));
    //color = lerp(color, float3(0.0, 1.0, 0.0), plotLineY(uv, t.g));
    //color = lerp(color, float3(0.0, 0.0, 1.0), plotLineY(uv, t.b));
     
    return float4(color, 1.0f);
}