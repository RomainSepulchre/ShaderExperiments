cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform Texture2D mainTex : register(t0);
uniform SamplerState mainTex_ST : register(s0);

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
	float2 texel = 1.0 / uResolution;
    float2 uv = fragCoord.xy * texel;  
    
    float4 noBlur = mainTex.Sample(mainTex_ST, uv);
    
    return noBlur;
}
