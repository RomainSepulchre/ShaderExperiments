// Based on https://www.shadertoy.com/view/XsfSD4

cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform float uvScale;
uniform float3 colorA;
uniform float4 d;
uniform float4 d2;

float hash2x1(in float2 uv)
{
    // Original author suggest to replace this by something better
    uv = 50.0 * frac (uv * 0.3183099 + float2(0.71,0.113));
    return frac(uv.x * uv.y * (uv.x + uv.y));
}

float2 hash2x2(in float2 uv)
{
	float2 offsetX = float2(0.0,0.0);
	float2 offsetY = float2(0.7,0.5);
    return float2(hash2x1(uv.xy + offsetX), hash2x1(uv.yx + offsetY));
}

float perlinNoise(in float2 uv)
{
    float2 gridID = floor(uv);
    float2 gridUv = frac(uv);
	uv = gridUv * gridUv * (3.0-2.0 * gridUv);
	
	float2 botL = hash2x2(gridID + float2(0.0, 0.0));
	float2 botR = hash2x2(gridID + float2(1.0, 0.0));
	float2 topL = hash2x2(gridID + float2(0.0, 1.0));
	float2 topR = hash2x2(gridID + float2(1.0, 1.0));
	
	// Remap value from [0,1] to [-1,1] and calculate dot product
	float dotBotL = dot(-1.0 + 2.0 * botL, gridUv - float2(0.0, 0.0));
	float dotBotR = dot(-1.0 + 2.0 * botR, gridUv - float2(1.0, 0.0));
	float dotTopL = dot(-1.0 + 2.0 * topL, gridUv - float2(0.0, 1.0));
	float dotTopR = dot(-1.0 + 2.0 * topR, gridUv - float2(1.0, 1.0));
	
	float bottom = lerp(dotBotL, dotBotR, uv.x);
	float top = lerp(dotTopL, dotTopR, uv.x);

	
    float pNoise = lerp(bottom, top, uv.y);
	
	return 0.5 + 0.5 * pNoise; // Remap value from [-1,1] to [0,1]
}

float perlinFbm(in float2 uv)
{
	float fbm = 0.0;
	uv = 6.0 * uv;

	float amplitude = 0.5;
	float scale = 1.0;
	
	float warpIntensity = 1.25;
	float warpSpeed = 0.1;
	int octaves = 8;
	
	for( int i=0; i<octaves; i++ )
    {
		float pNoise = perlinNoise(uv * scale);
		fbm += amplitude * pNoise;

		// Warp uv.y value to deform on Y axis
		// -> Remap noise from [0,1] to [-1,1]: (-1.0 + 2.0 * pNoise)
        uv.y -= warpIntensity * (-1.0 + 2.0 * pNoise) - warpSpeed * uTime * amplitude;
		
		amplitude *= 0.5;
		scale *= 2.0;

	}
	
    return fbm;	
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
	float2 uv = (fragCoord.xy / uResolution.x) * uvScale; // Scale with width
    //float2 uv = (fragCoord.xy/uResolution) * uvScale; // uniform scaling
    
    float pFbm = perlinFbm(uv);
    
    // Normal
    // e = Epsilon
    // -> extremely small value used for calculating finite differences to approximate surface tangents and normals.
	float2 e = float2(0.03, 0.0);
	float normalX = perlinFbm(uv - e.xy) - perlinFbm(uv + e.xy);
	float normalY = 2.0 * e.x;
	float normalZ = perlinFbm(uv - e.yx) - perlinFbm(uv + e.yx);
	float3 normal = normalize(float3(normalX, normalY,  normalZ));
	
	// Color
	float3 mainColor = float3(0.8, 0.4, 0.0);
	mainColor = colorA;
	float mask = pow(pFbm, 4.0) * 6.0; // ??? 4.0 and 6.0	
	float3 color = 0.5 + 0.5 * cos(5.0 + pFbm * 12.0 + mainColor);
	
    color *= 0.4 + 0.6 * mask;
    
    // Light	
	float3 lightDir = normalize(float3(1.0, 0.2, 1.0));
	float lightMap = clamp(0.3 + 0.7 * dot(normal,lightDir), 0.0, 1.0);
	float3 shadowColor = float3(0.6, 0.7, 0.8);
	float3 lightColor = float3(1.0, 0.7, 0.5);
	color *= shadowColor + 1.0 * lightColor * lightMap; // Apply light
	
	// Rim light
	float3 rimLightColor = float3(1.0, 0.5, 0.0);
	float3 rimLight = 1.5 * rimLightColor * pow(1.0 - normal.y, 2.0) * mask;
	color += rimLight;
	
	// Post process
	color = sqrt(color) - 0.15;
    color *= sqrt(1.0 - 0.5 * abs(uv.x - 0.5));	// Vignette
    
    return float4(color, 1.0f);
}
