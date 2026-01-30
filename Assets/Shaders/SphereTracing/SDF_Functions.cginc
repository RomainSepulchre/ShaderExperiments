// Functions to draw geometry with SDF
// Based on https://iquilezles.org/articles/distfunctions/

static const float PI = 3.14159265359f;

// ------------------
// ----- SHAPES -----
// ------------------

/// Sphere
/// @param pos Position of the shape
/// @param radius Radius of the sphere
/// @return Sphere SDF value
inline float sdfSphere( float3 pos, float radius)
{
    return length(pos) - radius;
}

/// Box
/// @param pos Position of the shape
/// @param boxSize Size of the box
/// @return Box SDF value
inline float sdfBox( float3 pos, float3 boxSize)
{
    float3 q = abs(pos) - boxSize;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y,q.z)), 0.0);
}

/// Rounded Box
/// @param pos Position of the shape
/// @param boxSize Size of the box
/// @param round 0.0 to 1.0 value that define how rounded is the box
/// @return Rounded box SDF value
inline float sdfRoundBox( float3 pos, float3 boxSize, float round)
{
    float3 q = abs(pos) - boxSize + round;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - round;
}

/// Box Frame
/// @param pos Position of the shape
/// @param boxSize Size of the box
/// @param frameThickness 
/// @return Box frame SDF value
inline float sdfBoxFrame(float3 pos, float3 boxSize, float frameThickness)
{
    pos = abs(pos) - boxSize;
    float3 q = abs(pos + frameThickness) - frameThickness;
    return min(min(
        length(max(float3(pos.x,q.y, q.z), 0.0)) + min(max(pos.x, max(q.y,q.z)), 0.0),
        length(max(float3(q.x, pos.y, q.z), 0.0)) + min(max(q.x, max(pos.y,q.z)), 0.0)),
        length(max(float3(q.x, q.y, pos.z), 0.0)) + min(max(q.x, max(q.y,pos.z)), 0.0));
}

/// Plane
/// @param pos Position of the shape
/// @param normal Normal of the plane (must be a normalized vector)
/// @param height Optional parameter to modify the height of the plane
/// @return Plane SDF value
float sdfPlane(float3 pos, float3 normal, float height = 0)
{
    // normal must be normalized
    return dot(pos, normal) + height;
}

/// Torus
/// @param pos Position of the shape
/// @param radius Radius of the torus
/// @param thickness Thickness of the torus
/// @return Torus SDF value
inline float sdfTorus( float3 pos, float radius, float thickness)
{
    float2 q = float2(length(pos.xz) - radius, pos.y);
    return length(q) - thickness;
}

/// Capped Torus
/// @param pos Position of the shape
/// @param radius Radius of the torus
/// @param thickness Thickness of the torus
/// @param fill 0.0 to 1.0 value that define how the torus circle is filled
/// @return Capped Torus SDF value
inline float sdfCappedTorus( float3 pos, float radius, float thickness, float fill)
{
    float s = sin(lerp(0.0, PI, fill));
    float c = cos(lerp(0.0, PI, fill));
    float2 sc = float2(s, c);
    pos.x = abs(pos.x);
    float k = (sc.y * pos.x > sc.x * pos.y) ? dot(pos.xy, sc) : length(pos.xy);
    return sqrt(dot(pos, pos) + radius * radius - 2.0 * radius * k) - thickness;
}

/// Link
/// @param pos Position of the shape
/// @param size Size of the link (height and width)
/// @param thickness Thickness of the link
/// @return Link SDF value
float sdfLink( float3 pos, float2 size, float thickness )
{
    float3 q = float3( pos.x, max(abs(pos.y) - size.x, 0.0), pos.z );
    return length(float2(length(q.xy) - size.y, q.z)) - thickness;
}

/// Infinite cylinder on X Axis
/// @param pos Position of the shape
/// @param radius Radius of the cylinder
/// @param offset Optional parameter to offset the cylinder position
/// @return Infinite cylinder SDF value
float sdfInfiniteCylinderX( float3 pos, float radius, float2 offset = float2(0,0))
{
    return length(pos.yz - offset) - radius;
}
/// Infinite cylinder on Y Axis
/// @param pos Position of the shape
/// @param radius Radius of the cylinder
/// @param offset Optional parameter to offset the cylinder position
/// @return Infinite cylinder SDF value
float sdfInfiniteCylinderY( float3 pos, float radius, float2 offset = float2(0,0))
{
    return length(pos.xz - offset) - radius;
}
/// Infinite cylinder on Z Axis
/// @param pos Position of the shape
/// @param radius Radius of the cylinder
/// @param offset Optional parameter to offset the cylinder position
/// @return Infinite cylinder SDF value
float sdfInfiniteCylinderZ( float3 pos, float radius, float2 offset = float2(0,0))
{
    return length(pos.xy - offset) - radius;
}

// ------------------------
// ----- COMBINATIONS -----
// ------------------------

/// Union
/// - Note: produce true sdf (exterior and interior)
/// @param shapeA First shape SDF value
/// @param shapeB Second shape SDF value
/// @return SDF value of the shapes union
inline float opUnion( float shapeA, float shapeB)
{
    return min(shapeA, shapeB);
}

/// Smoothed Union
/// @param shapeA First shape SDF value
/// @param shapeB Second shape SDF value
/// @param t Smooth interpolation value (0.0 to 1.0)
/// @return SDF value of the shapes smoothed union
inline float opSmoothedUnion(float shapeA, float shapeB, float t)
{
    float h = clamp(0.5 + 0.5 * (shapeB - shapeA) / t, 0.0, 1.0);
    return lerp(shapeB, shapeA, h) - t * h * (1.0 - h);
}

/// Substraction
/// - Note: subtracted item depends on the order, produce only exterior sdf
/// @param shapeToSubtract Shape that will subtract from the other shape
/// @param subtractedShape Shape that will be subtracted
/// @return SDF value of the shapes subtraction
inline float opSubtraction( float shapeToSubtract, float subtractedShape)
{
    return max(-shapeToSubtract, subtractedShape);
}

/// Intersection
/// - Note: produce only exterior sdf
/// @param shapeA First shape SDF value
/// @param shapeB Second shape SDF value
/// @return SDF value of the shapes intersection
inline float opIntersection( float shapeA, float shapeB)
{
    return max(shapeA, shapeB);
}

/// XOR (Exclusive OR)
/// - Note: produce true sdf (exterior and interior)
/// @param shapeA First shape SDF value
/// @param shapeB Second shape SDF value
/// @return SDF value of the shapes XOR operation
inline float opXor( float shapeA, float shapeB)
{
    return max(min(shapeA, shapeB), -max(shapeA, shapeB));
}


// ---------------------
// ----- POSITIONS -----
// ---------------------

/// Mod position axis: Allow to repeat distance field along an axis
/// @param pos 
/// @param size 
/// @return 
inline float pMod1(inout float pos, float size)
{
    float halfSize = size * 0.5;
    float c = floor((pos + halfSize) / size);
    pos = fmod(pos + halfSize, size) - halfSize;
    pos = fmod(-pos + halfSize, size) - halfSize;
    
    return c;
}

