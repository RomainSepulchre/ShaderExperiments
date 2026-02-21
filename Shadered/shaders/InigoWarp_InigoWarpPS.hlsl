cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform float uvScale;

uniform float2x2 warpMatrix;

uniform float3 color1;
uniform float3 color2;
uniform float3 color3;
uniform float3 color4;
uniform float3 color5;

float sinNoise(in float2 uv)
{
	return sin(uv.x) * sin(uv.y);
}

float fbm4(float2 uv)
{
    float fbm = 0.0;
    
    fbm += 0.5000 * sinNoise(uv);
    uv = warpMatrix * uv * 2.02;
    
    fbm += 0.2500 * sinNoise(uv);
    uv = warpMatrix * uv * 2.03;
    
    fbm += 0.1250 * sinNoise(uv);
    uv = warpMatrix * uv * 2.01;
    
    fbm += 0.0625 * sinNoise(uv);
    
    return fbm / 0.9375;
}

float fbm6(float2 uv)
{
    float fbm = 0.0;
    
    fbm += 0.500000 * (0.5 + 0.5 * sinNoise(uv));
    uv = warpMatrix * uv * 2.02;
    
    fbm += 0.250000 * (0.5 + 0.5 * sinNoise(uv));
    uv = warpMatrix * uv * 2.03;
    
    fbm += 0.125000 * (0.5 + 0.5 * sinNoise(uv));
    uv = warpMatrix * uv * 2.01;
    
    fbm += 0.062500 * (0.5 + 0.5 * sinNoise(uv));
    uv = warpMatrix * uv * 2.04;
    
    fbm += 0.031250 * (0.5 + 0.5 * sinNoise(uv));
    uv = warpMatrix * uv * 2.01;
    
    fbm += 0.015625 * (0.5 + 0.5 * sinNoise(uv));
    
    return fbm / 0.96875;
}

float2 fbm4_2(float2 uv)
{
    return float2(fbm4(uv), fbm4(uv + float2(7.8)));
}

float2 fbm6_2(float2 uv)
{
    return float2(fbm6(uv + float2(16.8)), fbm6(uv + float2(11.5)));
}

float warp(float2 uv, out float4 colMask)
{
	float time = uTime;
	
    uv += 0.03 * sin(float2(0.27, 0.23) * time + length(uv) * float2(4.1, 4.3));

	float2 fbm_x4 = fbm4_2(0.9 * uv);

    fbm_x4 += 0.04 * sin(float2(0.12, 0.14) * time + length(fbm_x4));

    float2 fbm_x6 = fbm6_2( 3.0 * fbm_x4);

	colMask = float4(fbm_x4, fbm_x6);

    float w = 0.5 + 0.5 * fbm4(1.8 * uv + 6.0 * fbm_x6);

    return lerp(w, w * w * w * 3.5, w * abs(fbm_x6.x));
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = (uvScale * fragCoord.xy - uResolution.xy) / uResolution.y; // scale with width
    //float2 uv = (fragCoord.xy / uResolution) * uvScale; // uniform scaling
    
    float4 colMask = 0.0;
    float warpFbm = warp(uv, colMask);
    
    // Use color mask to mix colors
    float3 color = 0.0;
    color = lerp(color1, color2, warpFbm);
    color = lerp(color, color3, dot(colMask.zw, colMask.zw));
    color = lerp(color, color4, 0.2 + 0.5 * colMask.y * colMask.y);
    color = lerp(color, color5, 0.5 * smoothstep(1.2, 1.3, abs(colMask.z) + abs(colMask.w)));
    color = clamp(color * warpFbm * 2.0, 0.0, 1.0);
    
    // Calculate a normal
    // -> High quality but slower (manual derivative) 
    float e = uvScale / uResolution.y; // ??? Initially 2.0 / uResolution.y but i think it should be the scale used when defining uv
    float4 noUse; // dummy float4 for the colMask out argument
 	float3 normal = normalize(float3( warp(uv + float2(e, 0.0), noUse) - warpFbm, 
                                2.0 * e, // Why 2.0 ???
                                warp(uv + float2(0.0, e), noUse) - warpFbm));
    // -> Low quality but faster (gpu derivative)                        
    //normal = normalize(float3(ddx(warpFbm) * uResolution.x, 6.0, ddx(warpFbm) * uResolution.y));
                          
    float3 lightDir = normalize(float3( 0.9, 0.2, -0.4));
    float shadowMap = clamp(0.3 + 0.7 * dot(normal, lightDir), 0.0, 1.0);
    
    float3 lightColor = float3(0.70,0.90,0.95);
    float3 shadowColor = float3(0.15, 0.10, 0.05);
    
    float3 light = lightColor * (normal.y * 0.5 + 0.5) + shadowColor * shadowMap;
    color *= 1.2 * light; // Apply light on the color
    color = 1.0 - color; // Invert color
    color = 1.1 * color * color; // Make color more intense
    return float4(color, 1.0f);
    
     
                  
    
}