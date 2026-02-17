cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform float lineThickness = 1.0;
uniform float4 linePosAB;
uniform float2 linePosC;

// -----------------
// --- Functions ---
// -----------------

float lineSegment(float2 p, float2 a, float2 b, float thickness = 1.0)
{
	float2 pa = p - a;
	float2 ba = b - a;
	
	float h = clamp(dot(pa,ba) / dot(ba,ba), 0.0, 1.0 );
	
	return 1 - smoothstep(0.0, thickness / uResolution.x, length(pa - ba * h));
}


// ****************
// ***** Main *****
// ****************

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    
    
    float2 A = linePosAB.xy + (float2(sin(uTime), cos(uTime)) / 5);
    float2 B = linePosAB.zw + (float2(sin(uTime+1), cos(uTime+1)) / 5);
    float2 C = linePosC + (float2(sin(uTime+2), cos(uTime+2)) / 5);
    
    float line1 = lineSegment(uv, A, B, lineThickness);
    float line2 = lineSegment(uv, B, C, lineThickness);
    float line3 = lineSegment(uv, C, A, lineThickness);
    
    return line1 + line2 + line3;
    //return float4(uv, 0.0, 1.0);
}

