cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

Texture2D mainTex : register(t0);
SamplerState mainTex_ST : register(s0);

float2 turbulence(float2 uv, float frequency, float octaves)
{    
	float turbSpeed = 6.0;
	float turbAmplitude = 0.4;
	float turbExp = 1.3; // Frequency multiplier for each new octave

    //Turbulence rotation matrix
    float2x2 rot = float2x2(0.6, -0.8, 0.8, 0.6);
    
    //Loop through turbulence octaves
    for(float i=0.0; i<octaves; i++)
    {
        //Scroll along the rotated y coordinate
        float phase = frequency * (uv * rot).y + turbSpeed * uTime + i;
        //Add a perpendicular sine wave offset
        uv += turbAmplitude * rot[0] * sin(phase) / frequency;
        
        // Rotate and  scale down for the next octave
        rot *= float2x2(0.6, -0.8, 0.8, 0.6);
        frequency *= turbExp;
    }
    
    return uv;
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
	float uvScale = 2.0;
    float2 uv = (fragCoord.xy * uvScale - uResolution) / uResolution.y ;
    
    float2 defaultUv = uv;  
    
    // Stretch uv on both axis
    // -> ? Check X and Y strecth on desmos
    float xStretch = 2.0 - 1.5 * smoothstep(-2.0, 2.0, uv.y); // expand uv vertically
    float yStretch = 1.0 - 0.5 / (1.0 + uv.x * uv.x); // decelerate uv horizontally
    float2 stretch = float2(xStretch, yStretch);
    
    uv *= stretch;
    
    // Scroll UV upward
    float scrollSpeed = 1.6;
    float scroll = scrollSpeed * uTime;
    uv.y -= scroll;
    
    float turbFrequency = 7.0;
    float turbOctaves = 10.0;
    uv = turbulence(uv, turbFrequency, turbOctaves);
    
    // Revert scroll after turbulence has been calculated (otherwise we keep scrolling downward and no longer see the effect after a few seconds)
    uv.y += scroll;
    
    // Create a circle shape with the UV value for the fireball
    float fireRadius = 0.4;
    float fireCircle = length(min(uv, uv / float2(1, stretch.y))) - fireRadius;
    
    // Calculate a lightmap where outward is attenuated and that fade vertically
    float gradientFalloff = 0.3; // Define vertical fade
    float light = pow(fireCircle * fireCircle + gradientFalloff * max(uv.y + 0.5, 0.0), 3.0);
    light = 1.0 / light; // Invert values
    
    // Coordinates relative to the source
    float2 source = uv + 2.0 * float2(0, fireRadius) * stretch;
    
    // RGB falloff gradient
    float3 gradientColor = float3(9.0, 2.0, 1.0);
    float3 rgbGradient = 0.1 / (1.0 + 8.0 * length(source) / gradientColor);
    
    // Flicker
    float flickerSpeed = 12.0;
    float flickerIntensity = 0.12;
    float flickerTime = flickerSpeed * uTime;
    float flicker = 1.0 + flickerIntensity * cos(flickerTime + sin(flickerTime * 1.618 - uv.y));
    
    // Ambient lighting
    float3 ambientLight = 16.0 * flicker / (1.0 + dot(defaultUv,defaultUv)) * rgbGradient;
    
    // Calculate new vertical scrolling UV values for the texture and sample the texture
    float2 texUv = (uv - scrollSpeed * float2(0, uTime));
    texUv = texUv / 1e2 * turbFrequency; // Divide by a big value to zoom in the texture pixels
    float3 tex = mainTex.Sample(mainTex_ST, texUv).rgb;
    
	float3 color = ambientLight + light * rgbGradient * tex;
	
	// Exponential Tonemapping
	color = 1.0 - exp(-color);
	
    return float4(color, 1);
}