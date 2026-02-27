// Based on https://www.shadertoy.com/view/MdSXzz

cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform float uvScale = 2.0;

const float2x2 warpMatrix = float2x2( 0.80,  0.60, -0.60,  0.80 );

float hash(float2 uv)
{
	float h = dot(uv, float2(127.1, 311.7));
    return -1.0 + 2.0 * frac(sin(h) * 43758.5453123);
}

float valueNoise(in float2 uv)
{
    float2 gridId = floor(uv);
    float2 gridUv = frac(uv);
    
	uv = gridUv * gridUv * (3.0 - 2.0 * gridUv);
	
	float botL =  hash( gridId + float2(0.0,0.0));
	float botR =  hash( gridId + float2(1.0,0.0));
	float topL =  hash( gridId + float2(0.0,1.0));
	float topR =  hash( gridId + float2(1.0,1.0));
	
	float bot = lerp(botL, botR, uv.x);
	float top = lerp(topL, topR, uv.x);
	
	return lerp(bot, top, uv.y);
}

float fbm(float2 uv)
{
    float fbm = 0.0;    
    float scale = 2.0;
    
    // Amplitude start at 0.5000 and is divided by two for each new octaves
    fbm += 0.5000 * valueNoise(uv);
    uv = warpMatrix * uv * (scale + 0.02); //2.02;
    
    fbm += 0.2500 * valueNoise(uv);
    uv = warpMatrix * uv * (scale + 0.03); //2.03;
    
    fbm += 0.1250 * valueNoise(uv);
    uv = warpMatrix * uv * (scale + 0.01); //2.01;
    
    fbm += 0.0625 * valueNoise(uv);
    
    return fbm / 0.9375; // 0.9375 is the total of all amplitudes
}

float2 fbm2(in float2 uv)
{
    return float2(fbm(uv.xy), fbm(uv.yx));
}


float3 warpColor(float2 uv)
{   
    uv *= 0.7;
	
	float speed = 0.05;
	float2 fbmA = fbm2(4.0 * uv);
	float2 fbmB = fbm2(-speed * uTime + 2.0 * (uv + fbmA));
	float2 fbmC = fbm2(speed * uTime + uv + fbmB);
	
	float fbmDot = dot(fbmC, float2(1.0, -1.0)); // Simulate light with dot product
	
    float mask1 = smoothstep( -0.8, 0.8, fbmDot);
    float mask2 = smoothstep( -1.0, 1.0, fbm(uv));
    
    float3 colorA = float3(0.50,0.00,0.00);
    float3 colorB = float3(1.00,0.75,0.35);
    float3 colorC = float3(0.00,0.00,0.02);
    
    float3 colorOut = lerp(colorA, colorB, mask2);
    return lerp(colorOut , colorC, mask1);
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
 	float2 uv = (uvScale * fragCoord.xy - uResolution.xy) / uResolution.y; // height scaling   
    //float2 uv = uvScale * (fragCoord.xy/uResolution); // uniform scaling
    
    // e = Epsilon
    // -> extremely small value used for calculating finite differences to approximate surface tangents and normals.
    float e = 0.0045;

    float3 colA = warpColor(uv);
    float3 colB = warpColor(uv + float2(e,0.0));
    float3 colC = warpColor(uv + float2(0.0,e));
    
    // Luminance value
    // -> dot(color, float3(0.333)) calculate the average of the RGB components
    float lumiA = dot(colA, float3(0.333));
    float lumiB = dot(colB, float3(0.333));
    float lumiC = dot(colC, float3(0.333));
    
    // Use luminance difference to calculate the normal
    float3 normal = normalize(float3(lumiB - lumiA, e, lumiC - lumiA));
    
    float3 color = colA;
    
    float3 rimLightColor =  float3(1.0, 0.7, 0.6);
    float rimLightIntensity = 8.0;
    float rimLightMask = abs(2.0 * lumiA - lumiB - lumiC);   
	color += rimLightColor * rimLightIntensity * rimLightMask;
	
	// Lighten area with normal Y value
	color *= 1.0 + 0.2 * normal.y * normal.y; 
    color += 0.05 * normal.y * normal.y * normal.y;
	
	// Square vignette
	float2 vignUv = fragCoord.xy / uResolution;
	float vignIntensity = 0.1;
    color *= pow(16.0 * vignUv.x * vignUv.y * (1.0 - vignUv.x) * (1.0 - vignUv.y), vignIntensity);
    
    return float4(color, 1.0f);
    
}
