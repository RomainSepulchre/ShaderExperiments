cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
	float2 mousePos;
};

uniform float radius;
uniform float circleSmooth = 0.1; // Weird issue when using this "smooth" it's always set to 0 no matter value set in pinned tab.


float circle(float2 pos, float r)
{
	float c = length(pos) - r;
	return 1 - step(r, c);
}

float smoothCircle(float2 pos, float r, float s)
{
	float c = length(pos) - r;
	float minCircle = c - s;
    float maxCircle = c + s;
    return smoothstep(minCircle, maxCircle, radius);
}


float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    float4 uvCol = float4(uv.xy, 0, 1);
    
    float circle = circle(float2(0.5,0.5) - uv, radius * (sin(uTime)+1));
    float mouseCircle = smoothCircle(mousePos - uv, radius, circleSmooth);
    
    
   
    //return float4(0.5 + (sin(uTime) + 1) / 2, 0.5 + (cos(uTime) + 1 )/2, 1, 1) * uvCol;
    return uvCol + uvCol * mouseCircle + uvCol * (circle*0.1);
    //return float4(0.5f + 0.5f*cos(uTime+uv.yxy), 1.0f);
}

