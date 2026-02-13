uniform float2 mousePos;
uniform Texture2D tex : register(t0);
uniform SamplerState texSmp : register(s0);
uniform float4 varColor;

struct PSInput
{
	float4 Position : SV_POSITION;
	float4 Color : COLOR;
	float2 UV : TEXCOORD0;
	float4 Normal : TEXCOORD1;
};

float4 main(PSInput pin) : SV_TARGET
{
	float4 texCol = tex.Sample(texSmp, pin.UV) * varColor;
	pin.Color = float4(abs(pin.Normal.xyz), 1);
	float2 absMousePos = abs(mousePos);
	return pin.Color * float4(absMousePos.x, absMousePos.y, 1, 1) + texCol;
}
