uniform float time;
uniform float timeSpeed; 


cbuffer cbPerFrame : register(b0)
{
	float4x4 matVP;
	float4x4 matGeo;
};

struct VSInput
{
	float3 Position : POSITION;
	float3 Normal : NORMAL;
	float2 UV : TEXCOORD0;
};

struct VSOutput
{
	float4 Position : SV_POSITION;
	float4 Color : COLOR;
	float2 UV : TEXCOORD0;
	float4 Normal : TEXCOORD1;
};

VSOutput main(VSInput vin)
{
	VSOutput vout = (VSOutput)0;

	vout.Position = mul(mul(float4(vin.Position, 1.0f), matGeo), matVP);
	float4 offset = float4(sin(time * timeSpeed), cos(time * timeSpeed), 0, 0);
	vout.Position += offset;
	vout.Color = 1;
	vout.Normal = mul(mul(float4(vin.Normal, 0), matGeo), matVP);
	vout.UV = vin.UV;

	return vout;
}