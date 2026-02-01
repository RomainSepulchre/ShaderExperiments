// Functions to draw geometry with SDF
// Based on https://iquilezles.org/articles/distfunctions/


// ............
// Static const

static const float PI = 3.14159265359f;

// ............
// Axis #define: used like an enum to choose an axis

#define SDF_AXIS_X 0 // Use X axis to draw the shape
#define SDF_AXIS_Y 1 // Use Y axis to draw the shape
#define SDF_AXIS_Z 2 // Use Z axis to draw the shape

// ------------------
// ----- SHAPES -----
// ------------------

// ............
// Spheres

/// Sphere
/// @param pos Position of the shape
/// @param radius Radius of the sphere
/// @return Sphere SDF value
inline float sdfSphere(float3 pos, float radius)
{
    return length(pos) - radius;
}

/// Cut sphere
/// @param pos Position of the shape
/// @param radius Radius of the sphere
/// @param cutHeight Height of the sphere cut
/// @return Cut sphere SDF value
inline float sdfCutSphere(float3 pos, float radius, float cutHeight, int axis)
{
    float w = sqrt(radius * radius - cutHeight * cutHeight);

    float2 q; 
    if (axis == SDF_AXIS_X)
    {
        q = float2(length(pos.yz), pos.x);
    }
    else if (axis == SDF_AXIS_Z)
    {
        q = float2(length(pos.xy), pos.z);
    }
    else // Default is SDF_AXIS_Y
    {
        q = float2(length(pos.xz), pos.y);
    }
    
    float s = max((cutHeight - radius) * q.x * q.x + w * w * (cutHeight + radius - 2.0 * q.y), cutHeight * q.x - w * q.y);
    
    return (s < 0.0) ? length(q)-radius : (q.x < w) ? cutHeight - q.y : length(q - float2(w, cutHeight));
}

// ............
// Boxes

/// Box
/// @param pos Position of the shape
/// @param boxSize Size of the box
/// @return Box SDF value
inline float sdfBox(float3 pos, float3 boxSize)
{
    float3 q = abs(pos) - boxSize;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y,q.z)), 0.0);
}

/// Rounded Box
/// @param pos Position of the shape
/// @param boxSize Size of the box
/// @param round 0.0 to 1.0 value that define how rounded is the box
/// @return Rounded box SDF value
inline float sdfRoundBox(float3 pos, float3 boxSize, float round)
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

// ............
// Planes

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

// ............
// Torus

/// Torus
/// @param pos Position of the shape
/// @param radius Radius of the torus
/// @param thickness Thickness of the torus
/// @param axis Axis to use to draw shape: use SDF_AXIS_X (0), SDF_AXIS_Y (1) or SDF_AXIS_Z (2)
/// @return Torus SDF value
inline float sdfTorus(float3 pos, float radius, float thickness, int axis = SDF_AXIS_Y)
{
    float2 q;
    
    if (axis == SDF_AXIS_X)
    {
        q = float2(length(pos.yz) - radius, pos.x);
    }
    else if (axis == SDF_AXIS_Z)
    {
        q = float2(length(pos.xy) - radius, pos.z);
    }
    else // Default is SDF_AXIS_Y
    {
        q = float2(length(pos.xz) - radius, pos.y);
    }
    
    return length(q) - thickness;
}

/// Capped Torus
/// @param pos Position of the shape
/// @param radius Radius of the torus
/// @param thickness Thickness of the torus
/// @param fill 0.0 to 1.0 value that define how the torus circle is filled
/// @return Capped Torus SDF value
inline float sdfCappedTorus(float3 pos, float radius, float thickness, float fill,  int axis = SDF_AXIS_Y)
{
    float s = sin(lerp(0.0, PI, fill));
    float c = cos(lerp(0.0, PI, fill));
    float2 sc = float2(s, c);
    
    float k;
    if (axis == SDF_AXIS_X)
    {
        pos.y = abs(pos.y);
        k = (sc.y * pos.y > sc.x * pos.z) ? dot(pos.yz, sc) : length(pos.yz);
    }
    else if (axis == SDF_AXIS_Y)
    {
        pos.x = abs(pos.x);
        k = (sc.y * pos.x > sc.x * pos.z) ? dot(pos.xz, sc) : length(pos.xz);
    }
    else // Default is SDF_AXIS_Z
    {
        pos.x = abs(pos.x);
        k = (sc.y * pos.x > sc.x * pos.y) ? dot(pos.xy, sc) : length(pos.xy);
    }
    
    return sqrt(dot(pos, pos) + radius * radius - 2.0 * radius * k) - thickness;
}

/// Link
/// @param pos Position of the shape
/// @param width Width of the link
/// @param radius Radius of the link
/// @param thickness Thickness of the link
/// @param axis Axis to use to draw shape: use SDF_AXIS_X (0), SDF_AXIS_Y (1) or SDF_AXIS_Z (2)
/// @return Link SDF value
inline float sdfLink(float3 pos, float width, float radius, float thickness, int axis = SDF_AXIS_Z)
{
    if (axis == SDF_AXIS_X)
    {
        float3 q = float3(pos.x, pos.y, max(abs(pos.z) - width, 0.0));
        return length(float2(length(q.yz) - radius, q.x)) - thickness;
    }
    else if (axis == SDF_AXIS_Y)
    {
        float3 q = float3(max(abs(pos.x) - width, 0.0), pos.y, pos.z);
        return length(float2(length(q.xz) - radius, q.y)) - thickness;
    }
    else // Default is SDF_AXIS_Z
    {
        float3 q = float3(pos.x, max(abs(pos.y) - width, 0.0), pos.z);
        return length(float2(length(q.xy) - radius, q.z)) - thickness;
    }
}

// ............
// Cylinders

/// Cylinder
/// @param pos Position of the shape
/// @param start Offset from shape position to define cylinder start point
/// @param end Offset from shape position to define cylinder end point
/// @param radius Radius of the cylinder
/// @return Cylinder SDF value
float sdfCylinder( float3 pos, float3 start, float3 end, float radius)
{
    float3 ba = end - start;
    float3 pa = pos - start;
    float baba = dot(ba, ba);
    float paba = dot(pa, ba);
    float x = length(pa * baba - ba * paba) - radius * baba;
    float y = abs(paba - baba * 0.5) - baba * 0.5;
    float x2 = x * x;
    float y2 = y * y * baba;
    float d = (max(x, y) < 0.0) ? -min(x2, y2) : (((x > 0.0) ? x2 : 0.0) + ((y > 0.0) ? y2 : 0.0));
    return sign(d) * sqrt(abs(d)) / baba;
}

/// Cylinder oriented in a specific axis
/// @param pos Position of the shape
/// @param size Size of the cylinder 
/// @param radius Radius of the cylinder
/// @param axis Axis to use to draw shape: use SDF_AXIS_X (0), SDF_AXIS_Y (1) or SDF_AXIS_Z (2)
/// @return Cylinder oriented on a specific axis SDF value
inline float sdfCylinderAxis(float3 pos, float size, float radius, int axis = SDF_AXIS_Y)
{
    size *= 0.5f; // Divide size by 2 so a size of 1 draw a cylinder of 1 meter
    
    float2 d;
    if (axis == SDF_AXIS_X)
    {
        d = abs(float2(length(pos.yz), pos.x)) - float2(radius, size);
    }
    else if (axis == SDF_AXIS_Z)
    {
        d = abs(float2(length(pos.xy), pos.z)) - float2(radius, size);
    }
    else // Default is SDF_AXIS_Y
    {
        d = abs(float2(length(pos.xz), pos.y)) - float2(radius, size);
    }
    
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

/// Rounded cylinder
/// @param pos Position of the shape
/// @param size Size of the cylinder 
/// @param radius Radius of the cylinder
/// @param round Value that define how rounded are the cylinder cap
/// @param axis Axis to use to draw shape: use SDF_AXIS_X (0), SDF_AXIS_Y (1) or SDF_AXIS_Z (2)
/// @return Rounded cylinder SDF value
inline float sdfRoundedCylinder(float3 pos, float size, float radius, float round, int axis = SDF_AXIS_Y)
{
    size = size * 0.5; // Divide size by 2 so a size of 1 draw a cylinder of 1 meter
    
    float2 d;
    if (axis == SDF_AXIS_X)
    {
        d = float2(length(pos.yz) - radius + round, abs(pos.x) - size + round);
    }
    else if (axis == SDF_AXIS_Z)
    {
        d = float2(length(pos.xy) - radius + round, abs(pos.z) - size + round);
    }
    else // Default is SDF_AXIS_Y
    {
        d = float2(length(pos.xz) - radius + round, abs(pos.y) - size + round);
    }
    
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - round;
}

/// Infinite cylinder on X Axis
/// @param pos Position of the shape
/// @param radius Radius of the cylinder
/// @param axis Axis to use to draw shape: use SDF_AXIS_X (0), SDF_AXIS_Y (1) or SDF_AXIS_Z (2)
/// @param offset Optional parameter to offset the cylinder position
/// @return Infinite cylinder SDF value
inline float sdfInfiniteCylinder(float3 pos, float radius, int axis = SDF_AXIS_Y , float2 offset = float2(0,0))
{
    if (axis == SDF_AXIS_X)
    {
        return length(pos.yz - offset) - radius;
    }
    else if (axis == SDF_AXIS_Z)
    {
        return length(pos.xy - offset) - radius;
    }
    else // Default is SDF_AXIS_Y
    {
        return length(pos.xz - offset) - radius;
    }
}

// ............
// Cones

/// Cone
/// @param pos Position of the shape
/// @param radius Radius of the cone
/// @param height Height of the cone
/// @return Cone SDF value
inline float sdfCone(float3 pos, float radius, float height)
{
    float2 q = float2(radius, -height); // q is the point at the base in 2D

    float2 w = float2(length(pos.xz), pos.y);
    float2 a = w - q * clamp(dot(w, q) / dot(q, q), 0.0, 1.0 );
    float2 b = w - q * float2(clamp( w.x / q.x, 0.0, 1.0), 1.0);
    float k = sign(q.y);
    float d = min(dot(a, a), dot(b, b));
    float s = max(k * (w.x * q.y - w.y * q.x), k * (w.y - q.y));
    
    return sqrt(d) * sign(s);
}
/// @param pos Position of the shape
/// @param sinCosAngle Sin and cos of the cone angle
/// @param height Height of the cone
/// @return Cone SDF value
inline float sdfCone(float3 pos, float2 sinCosAngle, float height)
{
    // sc is the sin/cos of the angle, h is height
    // Alternatively pass q instead of (c,h),
    // which is the point at the base in 2D
    float2 q = height * float2(sinCosAngle.x / sinCosAngle.y, -1.0);
    
    float2 w = float2(length(pos.xz), pos.y);
    float2 a = w - q * clamp(dot(w, q) / dot(q, q), 0.0, 1.0 );
    float2 b = w - q * float2(clamp( w.x / q.x, 0.0, 1.0), 1.0);
    float k = sign(q.y);
    float d = min(dot(a, a), dot(b, b));
    float s = max(k * (w.x * q.y - w.y * q.x), k * (w.y - q.y));
    
    return sqrt(d) * sign(s);
}

/// Infinite Cone
/// @param pos Position of the shape
/// @param sinCosAngle Sin and cos of the cone angle
/// @return Infinite Cone SDF value
inline float sdfInfiniteCone(float3 pos, float2 sinCosAngle)
{
    // c is the sin/cos of the angle
    float2 q = float2(length(pos.xz), -pos.y);
    float d = length(q - sinCosAngle * max(dot(q, sinCosAngle), 0.0));
    
    return d * ((q.x * sinCosAngle.y - q.y * sinCosAngle.x  <0.0) ? -1.0 : 1.0);
}

/// Capped cone
/// @param pos Position of the shape
/// @param base Offset from shape position to define capped cone base point
/// @param top Offset from shape position to define capped top point
/// @param radiusBase Radius of the base cap of the capped cone
/// @param radiusTop Radius of the top cap of the capped cone
/// @return Capped Cone SDF value
inline float sdfCappedCone(float3 pos, float3 base, float3 top, float radiusBase, float radiusTop)
{
    float rba  = radiusTop - radiusBase;
    float baba = dot(top - base, top - base);
    float papa = dot(pos - base, pos - base);
    float paba = dot(pos - base, top - base) / baba;
    float x = sqrt(papa - paba * paba * baba);
    float cax = max(0.0, x - ((paba < 0.5) ? radiusBase : radiusTop));
    float cay = abs(paba - 0.5) - 0.5;
    float k = rba * rba + baba;
    float f = clamp((rba * (x - radiusBase) + paba * baba) / k, 0.0, 1.0);
    float cbx = x - radiusBase - f * rba;
    float cby = paba - f;
    float s = (cbx < 0.0 && cay < 0.0) ? -1.0 : 1.0;
    
    return s * sqrt(min(cax * cax + cay * cay * baba, cbx * cbx + cby * cby * baba));
}

/// Capped Cone oriented in a specific axis
/// @param pos Position of the shape
/// @param size Size of the base cap
/// @param radiusBase Radius of the base cap of the capped cone
/// @param radiusTop Radius of the top cap of the capped cone
/// @param axis Axis to use to draw shape: use SDF_AXIS_X (0), SDF_AXIS_Y (1) or SDF_AXIS_Z (2)
/// @return Capped Cone oriented in a specific axis SDF value
inline float sdfCappedConeAxis(float3 pos, float size, float radiusBase, float radiusTop, int axis = SDF_AXIS_Y)
{
    float2 q;
    
    if (axis == SDF_AXIS_X)
    {
        q = float2(length(pos.yz), pos.x);
    }
    else if (axis == SDF_AXIS_Z)
    {
        q = float2(length(pos.xy), pos.z);
    }
    else // Default is SDF_AXIS_Y
    {
        q = float2(length(pos.xz), pos.y);
    }
    
    float2 k1 = float2(radiusTop, size);
    float2 k2 = float2(radiusTop - radiusBase, 2.0 * size);
    float2 ca = float2(q.x - min(q.x, (q.y < 0.0) ? radiusBase : radiusTop), abs(q.y) - size);
    float2 cb = q - k1 + k2 * clamp(dot(k1 - q, k2) / dot(k2, k2), 0.0, 1.0);
    float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
    
    return s * sqrt(min(dot(ca, ca), dot(cb, cb)));
}

// ............
// Capsules

/// Capsule
/// @param pos Position of the shape
/// @param start Offset from shape position to define capsule start point
/// @param end Offset from shape position to define capsule end point
/// @param radius Radius of the capsule
/// @return Capsule SDF value
inline float sdfCapsule(float3 pos, float3 start, float3 end, float radius)
{
    float3 pa = pos - start;
    float3 ba = end - start;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0 );
    
    return length(pa - ba * h) - radius;
}

/// Capsule oriented in a specific axis
/// @param pos Position of the shape
/// @param size Size of the capsule
/// @param radius Radius of the capsule
/// @param axis Axis to use to draw shape: use SDF_AXIS_X (0), SDF_AXIS_Y (1) or SDF_AXIS_Z (2)
/// @return Capsule oriented on a specific axis SDF value
inline float sdfCapsuleAxis(float3 pos, float size, float radius, int axis = SDF_AXIS_Y)
{
    size = (size * 0.5) - radius; // Divide size by 2 and take radius into account so a size of 1 draw a capsule of 1 meter
    
    if (axis == SDF_AXIS_X)
    {
        pos.x -= clamp(pos.x, 0.0, size);
    }
    else if (axis == SDF_AXIS_Z)
    {
        pos.z -= clamp(pos.z, 0.0, size);
    }
    else // Default is SDF_AXIS_Y
    {
        pos.y -= clamp(pos.y, 0.0, size);
    }
    
    return length(pos) - radius;
}

// ............
// Prism

/// Hexagonal prism
/// @param pos Position of the shape
/// @param radius Radius of the hexagonal prism
/// @param depth Depth of the hexagonal prism
/// @return Hexagonal prism SDF value
inline float sdfHexPrism(float3 pos, float radius, float depth)
{
    const float3 k = float3(-0.8660254, 0.5, 0.57735);
    pos = abs(pos);
    pos.xy -= 2.0 * min(dot(k.xy, pos.xy), 0.0) * k.xy;
    float2 d = float2(length(pos.xy - float2(clamp(pos.x, -k.z * radius, k.z * radius), radius)) * sign(pos.y - radius), pos.z - depth);
    
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// ............
// Solid angle

/// Solid Angle
/// @param pos Position of the shape
/// @param sinCosAngle Sin and cos of the angle
/// @param radius Radius of the solid angle
/// @param axis Axis to use to draw shape: use SDF_AXIS_X (0), SDF_AXIS_Y (1) or SDF_AXIS_Z (2)
/// @return Solid Angle SDF value
inline float sdfSolidAngle(float3 pos, float2 sinCosAngle, float radius, int axis = SDF_AXIS_Y)
{
    // c is the sin/cos of the angle
    float2 q;
    if (axis == SDF_AXIS_X)
    {
        q = float2( length(pos.yz), pos.x);
    }
    else if (axis == SDF_AXIS_Z)
    {
        q = float2( length(pos.xy), pos.z);
    }
    else // Default is SDF_AXIS_Y
    {
        q = float2( length(pos.xz), pos.y);
    }
    
    float l = length(q) - radius;
    float m = length(q - sinCosAngle * clamp(dot(q, sinCosAngle), 0.0, radius));
    
    return max(l, m * sign(sinCosAngle.y * q.x - sinCosAngle.x * q.y));
}
/// @param pos Position of the shape
/// @param angle Angle of the solid angle
/// @param radius Radius of the solid angle
/// @param axis Axis to use to draw shape: use SDF_AXIS_X (0), SDF_AXIS_Y (1) or SDF_AXIS_Z (2)
/// @return Solid Angle SDF value
inline float sdfSolidAngle(float3 pos, float angle, float radius, int axis = SDF_AXIS_Y)
{
    float2 q;
    if (axis == SDF_AXIS_X)
    {
        q = float2( length(pos.yz), pos.x);
    }
    else if (axis == SDF_AXIS_Z)
    {
        q = float2( length(pos.xy), pos.z);
    }
    else // Default is SDF_AXIS_Y
    {
        q = float2( length(pos.xz), pos.y);
    }
    
    float2 sc = float2(sin(angle), cos(angle));
    float l = length(q) - radius;
    float m = length(q - sc * clamp(dot(q, sc), 0.0, radius));
    
    return max(l, m * sign(sc.y * q.x - sc.x * q.y));
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

