cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform float uvScale = 1.0;
uniform int octaves = 2.0;
uniform float3 colorA = float3(0.0, 0.25, 0.6);
uniform float3 colorB = 1.0;

uniform float4 debug;


#define FIX_FRACT_HASH 1000

float hash_2x1(in float2 uv)
{
#ifdef FIX_FRACT_HASH
    uv = sign(uv) * (floor(abs(uv)) + floor(frac(abs(uv))  *FIX_FRACT_HASH) / FIX_FRACT_HASH);
#endif

    // Not ideal according to the original shader author
    uv = 50.0 * frac(uv * 0.3183099 + float2(0.71, 0.113));
    return frac(uv.x * uv.y * (uv.x + uv.y));
}

float2 hash_2x2(in float2 uv)
{
    return float2(hash_2x1(uv.xy + float2(0.0,0.0)),
                hash_2x1(uv.yx + float2(0.7,0.5)));
}

float simpleNoise(in float2 uv)
{
    float2 gridId = floor(uv);
    float2 gridUv = frac(uv);
    
    gridUv = gridUv * gridUv * (3.0 - 2.0 * gridUv);
    float botL = hash_2x1(gridId + float2(0,0));
	float botR = hash_2x1(gridId + float2(1,0));
	float topL = hash_2x1(gridId + float2(0,1));
	float topR = hash_2x1(gridId + float2(1,1));
	
	float bot = lerp(botL, botR, gridUv.x);
	float top = lerp(topL, topR, gridUv.x);
	
    return -1.0 + 2.0 * lerp(bot, top, gridUv.y);
}

float voronoi(in float2 uv)
{
	float2 gridId = floor(uv);
	float2 gridUv = frac(uv);
	float vorNoise = 10.0; 
	for(int i=-1; i<=1; i++ )
	{
		for( int j = -1; j <=1; j++ )
	    {
	        float2 adjCell = float2(i, j);
	        float2 r = adjCell - gridUv + hash_2x2(gridId + adjCell);
	        
	        vorNoise = min(vorNoise, dot(r,r));
	    }
	}
    
	return vorNoise;
}

float fbmNoise(in float2 uv, in int octaves)
{
    const float2x2 turbulenceMatrix = float2x2( 0.8, 0.6, -0.6, 0.8 );

    float fbm = 0.0;
    float amplitude = 0.5;
    float totalAmplitude = 0.0;
    for(int i=0; i<octaves; i++ )
    {
        fbm += amplitude * simpleNoise(uv);
        totalAmplitude += amplitude;
        uv = turbulenceMatrix * uv * 2.01;
        amplitude *= 0.5;
    }
    return fbm/totalAmplitude;
}

float fbmVoronoi(in float2 uv)
{
    float fbm = 1.0;
    float amplitude = 1.0;
    
    int vOctaves = 8;
    for( int i=0; i < vOctaves; i++)
    {
        float vNoise = voronoi(uv);
        fbm = min(fbm, vNoise * amplitude);
        uv *= 2.0;
        amplitude *= 1.4;
    }
    return 3.0 * fbm;
}

float2 fbmNoise_2(in float2 uv, in int octaves)
{
	float2 offsetX = float2(0.0,0.0);
	float2 offsetY = float2(0.7,1.3);
    return float2(fbmNoise(uv.xy + offsetX, octaves), 
                  fbmNoise(uv.yx + offsetY, octaves));
}

// distortion
float2 dis(in float2 uv, in float time)
{
    
    time += 0.3 * sin(time); // accelerate time speed
    
    uv.x -= 0.2 * time; // Right to left scrolling

    // Wirl: Add multiple layers of waves
    const float sinAmplitude = 0.7;
    // wave = uv + sinAmplitude * sin(uv.yx * sinPeriod + sinOffset + time)
    uv += sinAmplitude * 0.5000 * sin(uv.yx * 1.4 + 0.0 + time);
    uv += sinAmplitude * 0.2500 * sin(uv.yx * 2.3 + 1.0 + time);
    uv += sinAmplitude * 0.1250 * sin(uv.yx * 4.2 + 2.0 + time);
    uv += sinAmplitude * 0.0625 * sin(uv.yx * 8.1 + 3.0 + time);
    
    // Add turbulence in the waves
	// Turbulence = uv + turbulenceNoiseMultiplier * fbmNoise_2(uvScaleMultiplier * uv - time * timerMultiplier, octaves);
    uv += 0.4 * fbmNoise_2(0.5 * uv - time * float2(0.9,0.18), octaves);

    return uv;
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
	float2 uv = (uvScale * fragCoord - uResolution.xy) / uResolution.y; // Height based scaling
    //float2 uv = (fragCoord.xy / uResolution) * uvScale; // Uniform scaling
    
    // distortion (and its velocity)
    const float dt = 0.01;
    float2 dis1 = dis(uv, uTime);
    float2 dis2 = dis(uv, uTime - dt);
    float disVelocity = length(dis1 - dis2) / dt;
    
    float mask = dis1.y - 0.5 * sin(1.57 * dis1.x); // Waves
    mask -= 0.5 * disVelocity * disVelocity * (0.5 - fbmVoronoi(0.5 * dis1)); // circles
    mask = 0.5 + 1.5 * fbmNoise(float2(2.5 * mask, 0.0), 10); // Lines
    
	float3 color = lerp(colorA, colorB, mask);
        
    // Vignette
    color *= 1.0 - 0.1 * dot(uv,uv);
    
    return float4(color, 1.0f);
}
