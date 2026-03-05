cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

//  Function from Iñigo Quiles
//  https://www.shadertoy.com/view/MsS3Wc

float3 rgb2hsb(in float3 rgb)
{	
	// constant vector used for permutation and comparison calculation
	// They are be assigned to p and q depending on the hue sector
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    
    // Reorganize component based on blue component
    // 	-> if blue < green we use float4(rgb.gb, K.xy)
    //     if green < blue we use float4(rgb.bg, K.wz) 
    // => we set the first component to be the biggest value between blue and green
    float4 p = lerp(float4(rgb.bg, K.wz), float4(rgb.gb, K.xy), step(rgb.b, rgb.g));
    
    // Reorganize component based on p.x component
    // -> if p.x < red we use float4(rgb.r, p.yzx)
    //    if red < p.x we use float4(p.xyw, rgb.r)
    // => we set the first component to be the biggest value between red, green and blue (p.x represent biggest the value between green and blue)
    float4 q = lerp(float4(p.xyw, rgb.r), float4(rgb.r, p.yzx), step(p.x, rgb.r));
    
    
    float d = q.x - min(q.w, q.y); // Difference between biggest and smallest value 
    
    float e = 1.0e-10; // extremely small value used to prevent division by 0
    
    // Hue
    // -> hue is usually represented as an angle on a chromatic circle, this circle has 6 sectors:
    //		- Red to Yellow (0° to 60°)
    //		- Red to Yellow (60° to 120°)
    //		- Red to Yellow (120° to 180°)
    //		- Red to Yellow (180° to 240°)
    //		- Red to Yellow (240° to 300°)
    //		- Red to Yellow (300° to 360°)
    // -> q.z define a sector and (q.w - q.y) / (6.0 * d + e) define the relative position in the sector
    // -> Since there is 6 sectors d is multiplied by 6.0 get a hue normalized to [0,1] after the division. (Otherwise the range is [0,6])
    float hue = q.z + (q.w - q.y) / (6.0 * d + e); // why * 6.0;
    
    // Saturation
    // -> difference between biggest and smallest value divided by biggest value
    float saturation = d / (q.x + e);
    
    // Brightness
    // -> value of the biggest component (Red, Green or Blue)
    float brightness = q.x;
    
    return float3(hue, saturation, brightness);
}


float3 hsb2rgb(in float3 hsb)
{
    float3 rgb = clamp(abs(fmod(hsb.x * 6.0 + float3(0.0,4.0,2.0), 6.0) -3.0) -1.0,
                     0.0,
                     1.0 );
    rgb = rgb * rgb * (3.0 - 2.0 * rgb);
    return hsb.z * lerp(float3(1.0), rgb, hsb.y);
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
	float2 uv = fragCoord.xy/uResolution;
	
	float3 color = 0.0;

    // We map x (0.0 - 1.0) to the hue (0.0 - 1.0)
    // And the y (0.0 - 1.0) to the brightness
    color = hsb2rgb(float3(uv.x, 1.0, uv.y));
    
	color = step(0.5, 0.0);
    return float4(color, 1.0f);
}