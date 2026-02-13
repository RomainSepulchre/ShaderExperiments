uniform float2 mousePos;
uniform Texture2D tex : register(t0);
uniform SamplerState texSmp : register(s0);
uniform Texture2D rTex : register(t1);
uniform SamplerState rTexSmp : register(s1);
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
	float4 rTexCol = rTex.Sample(rTexSmp, pin.UV);
	
	pin.Color = float4(abs(pin.Normal.xyz), 1);
	float2 absMousePos = abs(mousePos);
	float4 col = pin.Color * float4(absMousePos.x, absMousePos.y, 1, 1) + texCol;
	col -= rTexCol;
	return col;
}
