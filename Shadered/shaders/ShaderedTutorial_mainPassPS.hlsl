struct PSInput
{
        float4 Position : SV_POSITION;
        float4 Color : COLOR;
        float2 UV : TEXCOORD;
};

Texture2D tex : register(t0);
SamplerState smp : register(s0);

float4 main(PSInput pin) : SV_TARGET
{
		float4 texCol = tex.Sample(smp, pin.UV);
        return texCol > 0.0 ? texCol : pin.Color;
       
}