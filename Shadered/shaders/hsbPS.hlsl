cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

uniform float3 rgbColorPicker;

const float PI = 3.1415927;
const float TAU = 2 * PI;


//  Functions from Iñigo Quiles (https://www.shadertoy.com/view/MsS3Wc)  

float3 rgb2hsb(in float3 rgb)
{	
	// Constant vector storing hue sector offset used for permutation and comparison when calculating the hue
	// They are be assigned to p and q depending on the hue sector:
	//  - sector R to G = 0.0 (normalized hue range = [0,1/6])
	//  - sector G to R = 2/3 (normalized hue range = [5/6,1])
	//  - sector G to B = 1/3 (normalized hue range = [1/6,1/2])
	//  - sector B to G = 1/3 (normalized hue range = [1/2,2/3])
	//  - sector R to G = 2/3 (normalized hue range = [2/3,5/6])
	//  - sector R to G = 0.0 (normalized hue range = [5/6,1])
	// Note: -1.0/3.0 and -1.0 instead of 1/3 and 1.0 to combine permutations and hue calculation and optimize code 
    const float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    
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
    //		- Yellow to Green  (60° to 120°)
    //		- Green to Cyan (120° to 180°)
    //		- Cyan to Blue (180° to 240°)
    //		- Blue to Magenta (240° to 300°)
    //		- Magenta to Red (300° to 360°)
    // -> q.z define a sector and (q.w - q.y) / (6.0 * d + e) define the relative position in the sector
    // -> Since there is 6 sectors d is multiplied by 6.0 get a hue normalized to [0,1] after the division. (Otherwise the range is [0,6])
    float hue = abs(q.z + (q.w - q.y) / (6.0 * d + e));
    
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
	// hue converted to [0,6] range
	float hue6 = hsb.x * 6.0; 
	
	// Offset to identify current sector and calculate relative distance
	// 0.0, 4.0 and 2.0 are the offset for the Red, Green and Blue component of the hue
	// -> After the modulo each value have a normalized distance from the edge of their sector:
	// 		- Red: 0.0 (Red is dominant in sectors [0,1] and [5,6])
	//		- Green: 4.0 (Green is dominant in sectors [1,2] and [4,5])
	//		- Blue: 2.0 (Blue is dominant in sectors [2,3] and [3,4])
	float3 componentOffset = float3(0.0,4.0,2.0);
	
	float3 hueMod = fmod(hue6 + componentOffset, 6.0); // Use modulo to loop hue value bigger than 6.0 inside [0,6] range
	float3 hueCentered = abs(hueMod - 3.0); // Center hue value around 0 to facilitate relative position calculation and get absolute value to have positive distances
	
	// Offset value to range [-1, 1] and clamp them between 0.0 and 1.0 to get hue as RGB value
    float3 hueRgb = clamp(hueCentered - 1.0, 0.0, 1.0);
                     
    // Apply approximated gamma correction to smooth sector transition
    // -> hueRgb * hueRgb * (3.0 - 2.0 * hueRgb) is a simplified version of smoothstep()      
    hueRgb = hueRgb * hueRgb * (3.0 - 2.0 * hueRgb);
    
    // Calculate color RGB value
    // -> apply brightness by lerping between white and hue color with brighness component
    // -> multiply the result by the saturation component to apply saturation
    return hsb.z * lerp(float3(1.0), hueRgb, hsb.y);
}

float sdfCircle(float2 uv, float radius)
{
    return length(uv) - radius;
}

float3 drawHsbColorPicker(float2 uv, float3 rgbColorToPick)
{
	// We map x (0.0 - 1.0) to the hue (0.0 - 1.0)
    // And the y (0.0 - 1.0) to the brightness
	float3 hsbMap = hsb2rgb(float3(uv.x, 1.0, uv.y));
	
	// Color to pick converted to HSB
	float3 hsbColor = rgb2hsb(rgbColorToPick);
	
	// Update luminance on hsb map
	hsbMap *= hsbColor.z;
	
	// Cursor circle parameters
    float2 circlePos = hsbColor.xy;
    float circleRadius = 0.01;
    float borderThick = 0.002;
    float2 brCircleOffset = float2(0.025,0.025);
    
    // Move brighness circle to keep it inside the render
    if(circlePos.x > 0.95) brCircleOffset.x *= -1;
    if(circlePos.y > 0.95) brCircleOffset.y *= -1;
    
    // Color and brighness circle mask
    float circleIn = step(sdfCircle(uv - circlePos, circleRadius - borderThick), circleRadius - borderThick);
    float circleBorder = step(sdfCircle(uv - circlePos, circleRadius), circleRadius) - circleIn;
    float brightCircle = step(sdfCircle(uv - circlePos - brCircleOffset, circleRadius/2 - borderThick/2), circleRadius/2 - borderThick/2);
    float brightCircleBorder = step(sdfCircle(uv - circlePos - brCircleOffset, circleRadius/2), circleRadius/2) - brightCircle;
    
    // Mix colors together
    float3 color = saturate(hsbMap - (circleIn + circleBorder + brightCircle + brightCircleBorder)); // Clean circle pixels out of HsbMap and use saturate to clamp values in [0,1] range
    color += circleBorder;
    color += rgbColorPicker * circleIn;
    color += brightCircleBorder;
    color += brightCircle * hsbColor.z;
    
    return color;
	
}

float3 drawHsbPolarCoord(float2 uv, float3 rgbColorToPick)
{
	float2 centerDir = 0.5 - uv;
	float angle = atan2(centerDir.y, centerDir.x); // angle in radian between -PI and PI
	float radius = length(centerDir) * 2.0; // Radius max is 0.5 so we multiply it by two to have value in the [0,1] range
	
	// Draw HSB polar map
	// Hue: The angle has a range of [-Pi, Pi] and the hue need a value with the range [0,1] so we divide our angle by Tau and add 0.5
	// Saturation: we use the distance from center as a saturation value
	// Brighness: 1.0 by default
	
	float3 hsbMap = hsb2rgb(float3((angle/TAU) + 0.5, radius, 1.0));
	
	// Color to pick converted to HSB
	float3 hsbColor = rgb2hsb(rgbColorToPick);
	
	// Update luminance on hsb map
	hsbMap *= hsbColor.z;

	// Cursor circle parameters
	
	float colAngle = (hsbColor.x - 0.5) * TAU;
	float colRadius = hsbColor.y / 2;
    float2 circlePos = 0.5 + float2(-colRadius * cos(colAngle), -colRadius * sin(colAngle));
    
    float circleRadius = 0.01;
    float borderThick = 0.002;
    float2 brCircleOffset = float2(0.025,0.025);
    
    // Move brighness circle to keep it inside the render
    if(circlePos.x > 0.95) brCircleOffset.x *= -1;
    if(circlePos.y > 0.95) brCircleOffset.y *= -1;
    
    // Color and brighness circle mask
    float polarMask = step(sdfCircle(uv - 0.5, 0.25), 0.25);
    float circleIn = step(sdfCircle(uv - circlePos, circleRadius - borderThick), circleRadius - borderThick);
    float circleBorder = step(sdfCircle(uv - circlePos, circleRadius), circleRadius) - circleIn;
    float brightCircle = step(sdfCircle(uv - circlePos - brCircleOffset, circleRadius/2 - borderThick/2), circleRadius/2 - borderThick/2);
    float brightCircleBorder = step(sdfCircle(uv - circlePos - brCircleOffset, circleRadius/2), circleRadius/2) - brightCircle;
    
    // Mix colors together
    float3 color = polarMask * saturate(hsbMap - (circleIn + circleBorder + brightCircle + brightCircleBorder)); // Clean circle pixels out of HsbMap and use saturate to clamp values in [0,1] range
    color += circleBorder;
    color += rgbColorPicker * circleIn;
    color += brightCircleBorder;
    color += brightCircle * hsbColor.z;

	return color;
}

float3 drawHsbPolarCoordAnimated(float2 uv, float3 rgbColorToPick)
{
	float2 centerDir = 0.5 - uv;
	float angle = atan2(centerDir.y, centerDir.x); // angle in radian between -PI and PI
	float radius = length(centerDir) * 2.0; // Radius max is 0.5 so we multiply it by two to have value in the [0,1] range
	
	// Draw HSB polar map
	// Hue: The angle has a range of [-Pi, Pi] and the hue need a value with the range [0,1] so we divide our angle by Tau and add 0.5
	// Saturation: we use the distance from center as a saturation value
	// Brighness: 1.0 by default
	float angleOffset = 0.5 * (uTime * 0.05);
	float3 hsbMap = hsb2rgb(float3((angle/TAU) + angleOffset, radius, 1.0));
	
	// Color to pick converted to HSB
	float3 hsbColor = rgb2hsb(rgbColorToPick);
	
	// Update luminance on hsb map
	hsbMap *= hsbColor.z;

	// Cursor circle parameters
	
	float colAngle = (hsbColor.x - angleOffset) * TAU;
	float colRadius = hsbColor.y / 2;
    float2 circlePos = 0.5 + float2(-colRadius * cos(colAngle), -colRadius * sin(colAngle));
    
    float circleRadius = 0.01;
    float borderThick = 0.002;
    float2 brCircleOffset = float2(0.025,0.025);
    
    // Move brighness circle to keep it inside the render
    if(circlePos.x > 0.95) brCircleOffset.x *= -1;
    if(circlePos.y > 0.95) brCircleOffset.y *= -1;
    
    // Color and brighness circle mask
    float polarMask = step(sdfCircle(uv - 0.5, 0.25), 0.25);
    float circleIn = step(sdfCircle(uv - circlePos, circleRadius - borderThick), circleRadius - borderThick);
    float circleBorder = step(sdfCircle(uv - circlePos, circleRadius), circleRadius) - circleIn;
    float brightCircle = step(sdfCircle(uv - circlePos - brCircleOffset, circleRadius/2 - borderThick/2), circleRadius/2 - borderThick/2);
    float brightCircleBorder = step(sdfCircle(uv - circlePos - brCircleOffset, circleRadius/2), circleRadius/2) - brightCircle;
    
    // Mix colors together
    float3 color = polarMask * saturate(hsbMap - (circleIn + circleBorder + brightCircle + brightCircleBorder)); // Clean circle pixels out of HsbMap and use saturate to clamp values in [0,1] range
    color += circleBorder;
    color += rgbColorPicker * circleIn;
    color += brightCircleBorder;
    color += brightCircle * hsbColor.z;

	return color;
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
	float2 uv = fragCoord.xy/uResolution;
	 
	float3 color = 0.0;
	
	// HSB Normal Color picker
    color = drawHsbColorPicker(uv, rgbColorPicker);
    
    // HSB Polar Color picker
    color = drawHsbPolarCoord(uv, rgbColorPicker);
    
    // HSB Animated Polar Color picker
    //color = drawHsbPolarCoordAnimated(uv, rgbColorPicker);
    
    return float4(color, 1.0f);
}