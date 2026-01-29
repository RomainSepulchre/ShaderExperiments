// Functions to draw geometry with SDF
// Based on https://iquilezles.org/articles/distfunctions/

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
    float halfSize = size / 0.5;
    float c = floor((pos + halfSize) / size);
    pos = fmod(pos + halfSize, size) - halfSize;
    pos = fmod(-pos + halfSize, size) - halfSize;
    
    return c;
}

