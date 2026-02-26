// Based on https://www.shadertoy.com/view/4s23zz

 // Enable/Disable antialiasing based on device performance
 // -> ? I need more info on HW_PERFORMANCE, it seems platform dependant
#if HW_PERFORMANCE==0
	#define AA 1
#else
	#define AA 2
#endif

cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform float uvScale;

float hash(float2 uv) 
{
	// original author suggest to replace this by something better
    uv = frac(uv * 0.6180339887);
    uv *= 25.0;
    return frac(uv.x * uv.y * (uv.x + uv.y) );
}


float perlinNoise(in float2 uv)
{
	// original author suggest to replace this by a proper noise function
    float2 gridId = floor(uv);
    float2 gridUv = frac(uv);
    gridUv = gridUv * gridUv * (3.0 - 2.0 * gridUv);
    
    float botL = hash(gridId + float2(0,0));
	float botR = hash(gridId + float2(1,0));
	float topL = hash(gridId + float2(0,1));
	float topR = hash(gridId + float2(1,1));
	
	float bot = lerp(botL, botR, gridUv.x);
	float top = lerp(topL, topR, gridUv.x);
	
    return lerp(bot, top, gridUv.y);
}

const float2x2 warpMatrix = float2x2(0.80,  0.60, -0.60,  0.80);

float fbm4(float2 uv)
{
	float fbm = 0.0;
	float scaleMultiplier = 2.0;
	
	// Amplitude start at 0.500000 and is divided by 2 for each new octaves
	// Small variations on the scaleMultiplier (2.02, 2.03,...) are part of the original code
	// -1.0 + 2.0 * noise(uv) = remap from [0,1] to [-1,1]
    
    fbm += 0.5000 * (-1.0 + 2.0 * perlinNoise(uv));
    uv = warpMatrix * uv * (scaleMultiplier + 0.02); //2.02;
    
    fbm += 0.2500 * (-1.0 + 2.0 * perlinNoise(uv));
    uv = warpMatrix * uv * (scaleMultiplier + 0.03); //2.03;
    
    fbm += 0.1250 * (-1.0 + 2.0 * perlinNoise(uv));
    uv = warpMatrix * uv * (scaleMultiplier + 0.01); //2.01;
    
    fbm += 0.0625 * (-1.0 + 2.0 * perlinNoise(uv));
    
    return fbm / 0.9375;
}

float fbm6(float2 uv)
{
    float fbm = 0.0;
    float scaleMultiplier = 2.0;
    
    // Amplitude start at 0.500000 and is divided by 2 for each new octaves
	// Small variations on the scaleMultiplier (2.02, 2.03,...) are part of the original code
	
    fbm += 0.500000 * perlinNoise(uv);
    uv = warpMatrix * uv * (scaleMultiplier + 0.02); //2.02;
    
    fbm += 0.250000 * perlinNoise(uv);
    uv = warpMatrix * uv * (scaleMultiplier + 0.03); //2.03;
    
    fbm += 0.125000 * perlinNoise(uv);
    uv = warpMatrix * uv * (scaleMultiplier + 0.01); //2.01;
    
    fbm += 0.062500 * perlinNoise(uv);
    uv = warpMatrix * uv * (scaleMultiplier + 0.04); //2.04;
    
    fbm += 0.031250 * perlinNoise(uv);
    uv = warpMatrix * uv * (scaleMultiplier + 0.01); //2.01;
    
    fbm += 0.015625 * perlinNoise(uv);
    
    return fbm / 0.984375; // 0.984375 = total of all the amplitudes
}

float2 fbm4_2(float2 uv)
{
	float2 offsetX = float2(1.0);
	float2 offsetY = float2(6.2);
    return float2(fbm4(uv + offsetX), fbm4(uv + offsetY));
}

float2 fbm6_2(float2 uv)
{
	float2 offsetX = float2(9.2);
	float2 offsetY = float2(5.7);
    return float2(fbm6(uv + offsetX), fbm6(uv + offsetY));
}

float warp(float2 uv, out float2 fbm1, out float2 fbm2)
{
    // Add subtle Ripple effect on UV
    float rippleIntensity = 0.05;
    float2 rippleSpeed = float2(0.11, 0.13);
    float rippleScale = 4.0;
    uv += rippleIntensity * sin(rippleSpeed * uTime + length(uv) * rippleScale);
    
     // Periodically darken uv
    float cosPeriod = 0.05;
    uv *= 0.7 + 0.2 * cos(cosPeriod * uTime);
    
    fbm1 = 0.5 + 0.5 * fbm4_2(uv); // fbm remapped to [0,1]
    
    // Add subtle Ripple effect on fbm1
    float fbmRippleInt = 0.02;
    float2 fbmRippleSpeed = float2(0.13, 0.11);
    fbm1 += fbmRippleInt * sin(fbmRippleSpeed * uTime * length(fbm1));
    
	// Second fbm pass on the first fbm value
    fbm2 = fbm6_2(4.0 * fbm1);

    float2 uv2 = uv + 2.0 * fbm2 + 1.0;
	
	
    float warpNoise = 0.5 + 0.5 * fbm4(2.0 * uv2);
    
    // Increase contrast with "warpNoise * abs(fbm2.x)" as interpolation value
    warpNoise = lerp(warpNoise, warpNoise * warpNoise * warpNoise * 3.5, warpNoise * abs(fbm2.x));
    
    // Create a mask to darken some area of the noise
    // -> 1.0 - ... : to invert mask
    // -> 0.5 + 0.5 * ... : to remap to [0,1]
    float2 maskScale = 8.0;
    float maskExponent = 8.0; // Control what part of the noise we keep
    float maskIntensity = 0.5;
    float mask = 1.0 - maskIntensity * pow(0.5 + 0.5 * sin(maskScale.x * uv2.x) * sin(maskScale.y * uv2.y), maskExponent);
    warpNoise *= mask; // Apply mask to darken noise

    return warpNoise;
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
	float3 color;
	
#if AA>1 // Start antialiasing for loop
	for(int i = 0; i < AA; i++)
	{
		for(int j = 0; j < AA; j++)
		{
			float aaOffset = float2(float(i), float(j)) / float(AA) - 0.5;
			//float2 uv = ((fragCoord.xy + aaOffset)  / uResolution) * uvScale; // uniform scaling
    		float2 uv = (uvScale * (fragCoord.xy + aaOffset) - uResolution.xy) / uResolution.y; // Scaling based on height with origin offset
	
#else
	//float2 uv = (fragCoord.xy / uResolution) * uvScale; // uniform scaling
    float2 uv = (uvScale * fragCoord.xy - uResolution.xy) / uResolution.y; // Scaling based on height with origin offset
#endif

	// Warped Noise
	float2 fbm1, fbm2;
	float warpNoise = warp(uv, fbm1, fbm2);
	
	//  Color
	float3 colorA = float3(0.2,0.1,0.4);
	float3 colorB = float3(0.3,0.05,0.05);
	float3 colorC = float3(0.9,0.9,0.9);
	float3 colorD = float3(0.5,0.2,0.2);
	float3 colorE = float3(0.0,0.2,0.4);
	
	float3 noiseColor = colorA;
	noiseColor = lerp(noiseColor, colorB, warpNoise); // Color mask is warp noise
	noiseColor = lerp(noiseColor, colorC, dot(fbm2, fbm2)); // Color mask is dot product of fbm2
	noiseColor = lerp(noiseColor, colorD, 0.5 * fbm1.y * fbm1.y); // Color mask 0.5 * fbm1^2
	noiseColor = lerp(noiseColor, colorE, 0.5 * smoothstep(1.2,1.3, abs(fbm2.y) + abs(fbm2.x))); // colorMask is smoothstep using fbm2 as interpolation value
	noiseColor *= warpNoise * 2.0; // Add back contrast
	
	// Normal
	// e = Epsilon (small value used to calculate normal)
	float2 ex = float2(1.0 / uResolution.x, 0.0);
	float2 ey = float2(0.0, 1.0 / uResolution.y);
	#if AA>1
		ex /= float(AA);
		ey /= float(AA);
	#endif
	float2 f1, f2; // dummy variable used to call warp()
	
	float normalX = warp(uv + ex, f1, f2) - warpNoise;
	float normalY = ex.x;
	float normalZ = warp(uv + ey, f1, f2) - warpNoise;
	
	float3 normal = normalize(float3(normalX, normalY, normalZ));
	
	// Light
	float3 lightDir = normalize(float3(0.9, -0.2, -0.4));
	float lightMap = clamp(0.3 + 0.7 * dot(normal, lightDir ), 0.0, 1.0);
	
	float3 lightColor = float3(0.85, 0.90, 0.95);
	float3 light = lightColor * (normal.y * 0.5 + 0.5);
	
	float3 shadowColor = float3(0.15,0.10,0.05);
    light += shadowColor * lightMap;
	
	noiseColor *= light; // Apply light
	
	// Post-Process
	noiseColor = 1.0 - noiseColor; // Negative effect
    noiseColor = noiseColor * noiseColor; // Boost colors
    noiseColor *= float3(1.2, 1.25, 1.2); // Lighten colors
	
	color += noiseColor;

#if AA>1 // End antialiasing for loop
		}
	}
	color /= float(AA * AA);
#endif
	
	// Square Vignette
	float2 vignUv = fragCoord / uResolution.xy; // use uniform scaling for vignette
	//color *= 0.5 + 0.5 * sqrt(16.0 * vignUv.x * vignUv.y * (1.0 - vignUv.x) * (1.0 - vignUv.y));
	color *= 0.5 + 0.5 * sqrt(16.0 * vignUv.x * vignUv.y * (1.0 - vignUv.x) * (1.0 - vignUv.y));
    
    return float4(color, 1.0f);
}
