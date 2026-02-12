// Functions to draw geometry with SDF
// Based on https://iquilezles.org/articles/distfunctions/

// TODO: find a way to implement -x, -y and -z axis
// -> bool in functions argument ?
// -> #define SDF_AXIS_MINUS_X, SDF_AXIS_MINUS_Y, SDF_AXIS_MINUS_Z ? -> add lots of code in every functions
// -> use rotation for this ?

// TODO: Make a HLSL version of this

// ............
// Static const

static const float PI = 3.14159265359f;

// ............
// Axis #define: used like an enum to choose an axis

#define SDF_AXIS_X 0 // Use X axis to draw the shape
#define SDF_AXIS_Y 1 // Use Y axis to draw the shape
#define SDF_AXIS_Z 2 // Use Z axis to draw the shape
//#define SDF_AXIS_MINUS_X 3 // Use -X axis to draw the shape
//#define SDF_AXIS_MINUS_Y 4 // Use -Y axis to draw the shape
//#define SDF_AXIS_MINUS_Z 5 // Use -Z axis to draw the shape



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
/// @param cut 0.0 to 1.0 value that define the cut position
/// @return Cut sphere SDF value
inline float sdfCutSphere(float3 pos, float radius, float cut, int axis = SDF_AXIS_Y)
{
    float cutHeight = lerp(-radius, radius, cut);
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

/// Cut hollow sphere
/// @param pos Position of the shape
/// @param radius Radius of the sphere
/// @param cut 0.0 to 1.0 value that define the cut position
/// @param thickness Thickness of the edge of the hollow sphere
/// @param axis Axis to use to draw shape: use SDF_AXIS_X (0), SDF_AXIS_Y (1) or SDF_AXIS_Z (2)
/// @return Cut hollow sphere SDF value
inline float sdfCutHollowSphere(float3 pos, float radius, float cut, float thickness, int axis = SDF_AXIS_Y)
{
    float cutHeight = lerp(radius, -radius, cut);
    float w = sqrt(radius * radius - cutHeight * cutHeight);
    
    float2 q;
    if (axis == SDF_AXIS_X)
    {
        q = float2(length(pos.yz), pos.x);
    }
    else  if (axis == SDF_AXIS_Z)
    {
        q = float2(length(pos.xy), pos.z);
    }
    else // Default is SDF_AXIS_Y
    {
        q = float2(length(pos.xz), pos.y);
    }
    
    return ((cutHeight * q.x < w * q.y) ? length(q - float2(w, cutHeight)) : abs(length(q) - radius)) - thickness;
}

/// Death Star
/// @param pos Position of the shape
/// @param radius Radius of the sphere
/// @param holeRadius Radius of the second sphere that subtract the hole
/// @param dist Distance between the main sphere and the hole sphere
/// @return Death Star SDF value
inline float sdfDeathStar(float3 pos, float radius, float holeRadius, float dist, int axis = SDF_AXIS_X)
{
    float a = (radius * radius - holeRadius * holeRadius + dist * dist) / (2.0 * dist);
    float b = sqrt(max(radius * radius - a * a, 0.0));
    
    float2 p;
    if (axis == SDF_AXIS_Y)
    {
        p = float2(pos.y, length(pos.xz));   
    }
    else if (axis == SDF_AXIS_Z)
    {
        p = float2(pos.z, length(pos.xy));       
    }
    else // Default is SDF_AXIS_X
    {
        p = float2(pos.x, length(pos.yz));
    }
    
    if(p.x * b - p.y * a > dist * max(b - p.y, 0.0))
    {
        return length(p - float2(a, b));
    }
    else
    {
        return max((length(p) - radius), -(length(p - float2(dist, 0.0)) - holeRadius));
    }
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
inline float sdfPlane(float3 pos, float3 normal, float height = 0)
{
    // normal must be normalized
    return dot(pos, normal) - height;
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
inline float sdfCylinder( float3 pos, float3 start, float3 end, float radius)
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
/// @param size Distance between the center and the base/top cap of the cylinder 
/// @param radius Radius of the cylinder
/// @param axis Axis to use to draw shape: use SDF_AXIS_X (0), SDF_AXIS_Y (1) or SDF_AXIS_Z (2)
/// @return Cylinder oriented on a specific axis SDF value
inline float sdfCylinderAxis(float3 pos, float size, float radius, int axis = SDF_AXIS_Y)
{    
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
/// @param size Distance between the center and the base/top cap of the cylinder
/// @param radius Radius of the cylinder
/// @param round Value that define how rounded are the cylinder cap
/// @param axis Axis to use to draw shape: use SDF_AXIS_X (0), SDF_AXIS_Y (1) or SDF_AXIS_Z (2)
/// @return Rounded cylinder SDF value
inline float sdfRoundedCylinder(float3 pos, float size, float radius, float round, int axis = SDF_AXIS_Y)
{    
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
/// @param sinCosAngle Sin and cos of the cone angle (in radians)
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
/// @param sinCosAngle Sin and cos of the cone angle (in radians)
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
/// @param size Distance between the center and the base/top cap of the cone
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

/// Round Cone
/// @param pos Position of the shape
/// @param base Offset from shape position to define round cone base point
/// @param top Offset from shape position to define round cone top point
/// @param baseRound Value that define how rounded is the base of the cone
/// @param topRound Value that define how rounded is the top of the cone
/// @return Round cone SDF value
inline float sdfRoundCone(float3 pos, float3 base, float3 top, float baseRound, float topRound)
{
    float3 ba = top - base;
    float l2 = dot(ba, ba);
    float rr = baseRound - topRound;
    float a2 = l2 - rr * rr;
    float il2 = 1.0/l2;
    
    float3 pa = pos - base;
    float y = dot(pa, ba);
    float z = y - l2;
    float x2 = dot(pa * l2 - ba * y, pa * l2 - ba * y);
    float y2 = y * y * l2;
    float z2 = z * z * l2;

    // single square root!
    float k = sign(rr) * rr * rr * x2;
    if(sign(z) * a2 * z2 > k) return sqrt(x2 + z2) * il2 - topRound;
    if(sign(y) * a2 * y2 < k) return sqrt(x2 + y2) * il2 - baseRound;
    return (sqrt(x2 * a2 * il2) + y * rr) * il2 - baseRound;
}

/// Round Cone oriented in a specific axis
/// @param pos Position of the shape
/// @param size Size of the cone
/// @param baseRound Value that define how rounded is the base of the cone
/// @param topRound Value that define how rounded is the top of the cone
/// @param axis Axis to use to draw shape: use SDF_AXIS_X (0), SDF_AXIS_Y (1) or SDF_AXIS_Z (2)
/// @return Round Cone oriented in a specific axis SDF value
inline float sdfRoundConeAxis(float3 pos, float size, float baseRound, float topRound, int axis = SDF_AXIS_Y)
{
    float b = (baseRound - topRound) / size;
    float a = sqrt(1.0 - b * b);

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
    
    float k = dot(q, float2(-b, a));
    if(k < 0.0) return length(q) - baseRound;
    if(k > a * size) return length(q - float2(0.0, size)) - topRound;
    return dot(q, float2(a,b)) - baseRound;
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
/// @param size Distance between the center and the base/top cap of the capsule
/// @param radius Radius of the capsule
/// @param axis Axis to use to draw shape: use SDF_AXIS_X (0), SDF_AXIS_Y (1) or SDF_AXIS_Z (2)
/// @return Capsule oriented on a specific axis SDF value
inline float sdfCapsuleAxis(float3 pos, float size, float radius, int axis = SDF_AXIS_Y)
{    
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
// Polygonal Shapes

/// Triangle
/// @param pos Position of the shape
/// @param aPoint Offset from shape position to define A point of the triangle
/// @param bPoint Offset from shape position to define B point of the triangle
/// @param cPoint Offset from shape position to define C point of the triangle
/// @return Triangle SDF value
inline float sdfTriangle(float3 pos, float3 aPoint, float3 bPoint, float3 cPoint)
{
    float3 ba = bPoint - aPoint; float3 pa = pos - aPoint;
    float3 cb = cPoint - bPoint; float3 pb = pos - bPoint;
    float3 ac = aPoint - cPoint; float3 pc = pos - cPoint;
    float3 nor = cross(ba, ac);
    
    float signBA = sign(dot(cross(ba, nor), pa));
    float signCB = sign(dot(cross(cb, nor), pb));
    float signAC = sign(dot(cross(ac, nor), pc));
    
    float dot2BA = dot(ba * clamp(dot(ba, pa) / dot(ba, ba), 0.0, 1.0) - pa, ba * clamp(dot(ba, pa) / dot(ba, ba), 0.0, 1.0) - pa);
    float dot2CA = dot(cb * clamp(dot(cb, pb) / dot(cb, cb), 0.0, 1.0) - pb, cb * clamp(dot(cb, pb) / dot(cb, cb), 0.0, 1.0) - pb);
    float dot2AC = dot(ac * clamp(dot(ac, pc) / dot(ac, ac), 0.0, 1.0) - pc, ac * clamp(dot(ac, pc) / dot(ac, ac), 0.0, 1.0) - pc);

    return sqrt((signBA + signCB + signAC < 2.0) ? min(min(dot2BA, dot2CA), dot2AC) : dot(nor, pa) * dot(nor, pa) / dot(nor, nor));
}

/// Quad
/// @param pos Position of the shape
/// @param aPoint Offset from shape position to define A point of the quad
/// @param bPoint Offset from shape position to define B point of the quad
/// @param cPoint Offset from shape position to define C point of the quad
/// @param dPoint Offset from shape position to define D point of the quad
/// @return Quad SDF value
inline float sdfQuad(float3 pos, float3 aPoint, float3 bPoint, float3 cPoint, float3 dPoint)
{
    float3 ba = bPoint - aPoint; float3 pa = pos - aPoint;
    float3 cb = cPoint - bPoint; float3 pb = pos - bPoint;
    float3 dc = dPoint - cPoint; float3 pc = pos - cPoint;
    float3 ad = aPoint - dPoint; float3 pd = pos - dPoint;
    float3 nor = cross(ba, ad);
    
    float signBA = sign(dot(cross(ba, nor), pa));
    float signCB = sign(dot(cross(cb, nor), pb));
    float signDC = sign(dot(cross(dc, nor), pc));
    float signAD = sign(dot(cross(ad, nor), pd));
    
    float dot2BA = dot(ba * clamp(dot(ba, pa) / dot(ba, ba), 0.0, 1.0) - pa, ba * clamp(dot(ba, pa) / dot(ba, ba), 0.0, 1.0) - pa);
    float dot2CB = dot(cb * clamp(dot(cb, pb) / dot(cb, cb), 0.0, 1.0) - pb, cb * clamp(dot(cb, pb) / dot(cb, cb), 0.0, 1.0) - pb);
    float dot2DC = dot(dc * clamp(dot(dc, pc) / dot(dc, dc), 0.0, 1.0) - pc, dc * clamp(dot(dc, pc) / dot(dc, dc), 0.0, 1.0) - pc);
    float dot2AD = dot(ad * clamp(dot(ad, pd) / dot(ad, ad), 0.0, 1.0) - pd, ad * clamp(dot(ad, pd) / dot(ad, ad), 0.0, 1.0) - pd);

    return sqrt((signBA + signCB + signDC + signAD <3.0) ?
       min(min(min(dot2BA, dot2CB), dot2DC), dot2AD) : dot(nor,pa) * dot(nor, pa) / dot(nor, nor));
}

/// Pyramid
/// @param pos Position of the shape
/// @param height Height of the pyramid
/// @return Pyramid SDF value
inline float sdfPyramid(float3 pos, float height)
{
    float m2 = height * height + 0.25;
    
    pos.xz = abs(pos.xz);
    pos.xz = (pos.z > pos.x) ? pos.zx : pos.xz;
    pos.xz -= 0.5;

    float3 q = float3(pos.z, height * pos.y - 0.5 * pos.x, height * pos.x + 0.5 * pos.y);
    float s = max(-q.x, 0.0);
    float t = clamp((q.y - 0.5 * pos.z) / (m2 + 0.25), 0.0, 1.0);
    float a = m2 * (q.x + s) * (q.x + s) + q.y * q.y;
    float b = m2 * (q.x + 0.5 * t) * (q.x + 0.5 * t) + (q.y - m2 * t) * (q.y - m2 * t);
    
    float d2 = min(q.y, -q.x * m2 - q.y * 0.5) > 0.0 ? 0.0 : min(a,b);
    return sqrt((d2 + q.z * q.z) / m2) * sign(max(q.z, -pos.y));
}

/// Octahedron
/// @param pos Position of the shape
/// @param size Size of the Octahedron
/// @return Octahedron SDF value
inline float sdfOctahedron(float3 pos, float size)
{
    pos = abs(pos);
    float m = pos.x + pos.y + pos.z - size;
    float3 q;
    
    if(3.0 * pos.x < m) q = pos.xyz;
    else if(3.0 * pos.y < m ) q = pos.yzx;
    else if(3.0 * pos.z < m ) q = pos.zxy;
    else return m * 0.57735027;
    
    float k = clamp(0.5 * (q.z - q.y + size), 0.0, size); 
    return length(float3(q.x, q.y - size + k, q.z - k)); 
}

/// Octahedron bound (not exact)
/// @param pos Position of the shape
/// @param size Size of the Octahedron
/// @return Octahedron bound SDF value
inline float sdfOctahedronBound(float3 pos, float size)
{
    pos = abs(pos);
    return (pos.x + pos.y + pos.z - size) * 0.57735027;
}

/// Triangular prism (Approximate SDF value)
/// @param pos Position of the shape
/// @param height Height of the triangular prism
/// @param depth Depth of the triangular prism
/// @return Triangular prism SDF value
inline float sdfTrianglePrism(float3 pos, float height, float depth)
{
    float3 q = abs(pos);
    return max(q.z - depth, max(q.x * 0.866025 + pos.y * 0.5, -pos.y) - height * 0.5);
}

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

/// Rhombus
/// @param pos Position of the shape
/// @param width Width of the Rhombus
/// @param depth Depth of the Rhombus
/// @param height Height of the Rhombus
/// @param cornerRadius Radius of the corner of the rhombus
/// @return Rhombus SDF value
inline float sdfRhombus(float3 pos, float width, float height, float depth, float cornerRadius)
{
    pos = abs(pos);
    float f = clamp((width * pos.x - depth * pos.z + depth * depth) / (width * width + depth * depth), 0.0, 1.0);
    float2 w = pos.xz - float2(width, depth) * float2(f, 1.0 - f);
    float2 q = float2(length(w) * sign(w.x) - cornerRadius, pos.y - height);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0));
}

// ............
// Other Shapes

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

/// Vesica Segment
/// @param pos Position of the shape
/// @param start Offset from shape position to define vesica segment start point
/// @param end Offset from shape position to define vesica segment end point
/// @param thickness Thickness of the vesica segment
/// @return Vesica segment SDF value
inline float sdfVesicaSegment(in float3 pos, in float3 start, in float3 end, in float thickness)
{
    float3 c = (start + end) * 0.5;
    float l = length(end - start);
    float3 v = (end - start) / l;
    float y = dot(pos - c, v);
    float2 q = float2(length(pos - c - y * v), abs(y));
    
    float r = 0.5 * l;
    float d = 0.5 * (r * r - thickness * thickness) / thickness;
    float3 h = (r * q.x < d * (q.y - r)) ? float3(0.0, r, 0.0) : float3(-d, 0.0, d + thickness);
 
    return length(q - h.xy) - h.z;
}

/// Ellipsoid (Approximate SDF value)
/// @param pos Position of the shape
/// @param xyzRadius Radius of the ellipsoid XYZ axis
/// @return Ellipsoid SDF value
inline float sdfEllipsoid(float3 pos, float3 xyzRadius)
{
    float k0 = length(pos / xyzRadius);
    float k1 = length(pos /( xyzRadius * xyzRadius));
    return k0 * (k0 - 1.0) / k1;
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
inline float opSmoothUnion(float shapeA, float shapeB, float t)
{
    float h = clamp(0.5 + 0.5 * (shapeB - shapeA) / t, 0.0, 1.0);
    return lerp(shapeB, shapeA, h) - t * h * (1.0 - h);
}
/// @param shapeA First shape SDF value
/// @param shapeB Second shape SDF value
/// @param t Smooth interpolation value (0.0 to 1.0)
/// @return SDF value of the shapes smoothed union
inline float opSmoothUnionX4(float shapeA, float shapeB, float t)
{
    // Different way of getting smoothed min, t is also multiplied by 4 
    t *= 4.0;
    float h = max(t - abs(shapeA - shapeB), 0.0);
    return min(shapeA, shapeB) - h * h * 0.25 / t;
}

/// Substraction
/// - Note: subtracted item depends on the order, produce only exterior sdf
/// @param shapeToSubtract SDF value of the shape that will subtract from the other shape
/// @param otherShape SDF value of the shape that will be subtracted
/// @return SDF value of the shapes subtraction
inline float opSubtraction( float shapeToSubtract, float otherShape)
{
    return max(-shapeToSubtract, otherShape);
}

/// Smooth Substraction
/// @param shapeToSubtract SDF value of the shape that will subtract from the other shape
/// @param otherShape SDF value of the shape that will be subtracted
/// @param t Smooth interpolation value (0.0 to 1.0)
/// @return SDF value of the shapes smoothed subtraction
inline float opSmoothSubtraction(float shapeToSubtract, float otherShape, float t)
{
    return -opSmoothUnion(shapeToSubtract, -otherShape, t);
}

/// Intersection
/// - Note: produce only exterior sdf
/// @param shapeA First shape SDF value
/// @param shapeB Second shape SDF value
/// @return SDF value of the shapes intersection
inline float opIntersection(float shapeA, float shapeB)
{
    return max(shapeA, shapeB);
}

/// Smooth Intersection
/// @param shapeA First shape SDF value
/// @param shapeB Second shape SDF value
/// @param t Smooth interpolation value (0.0 to 1.0)
/// @return SDF value of the shapes smoothed intersection
inline float opSmoothIntersection(float shapeA, float shapeB, float t)
{
    return -opSmoothUnion(-shapeA, -shapeB, t);
}

/// XOR (Exclusive OR: render only the areas where they not overlap)
/// - Note: produce true sdf (exterior and interior)
/// @param shapeA First shape SDF value
/// @param shapeB Second shape SDF value
/// @return SDF value of the shapes XOR operation
inline float opXor(float shapeA, float shapeB)
{
    return max(min(shapeA, shapeB), -max(shapeA, shapeB));
}



// ------------------------------------
// ----- COMBINATIONS WITH COLORS -----
// ------------------------------------

/// Union
/// - Note: produce true sdf (exterior and interior)
/// @param shapeA First shape color and SDF value (XYZ = RGB color, W = SDF value)
/// @param shapeB Second shape color and SDF value (XYZ = RGB color, W = SDF value)
/// @return Color and SDF value of the shapes union (XYZ = RGB color, W = SDF value)
inline float4 opUnion(float4 shapeA, float4 shapeB)
{
    float shape = min(shapeA.w, shapeB.w);
    float3 color = shape == shapeA.w ? shapeA.rgb : shapeB.rgb;
    return float4(color, shape);
}

/// Smoothed Union
/// @param shapeA First shape color and SDF value (XYZ = RGB color, W = SDF value)
/// @param shapeB Second shape color and SDF value (XYZ = RGB color, W = SDF value)
/// @param t Smooth interpolation value (0.0 to 1.0)
/// @return Color and SDF value of the shapes smoothed union (XYZ = RGB color, W = SDF value)
inline float4 opSmoothUnion(float4 shapeA, float4 shapeB, float4 t)
{
    float h = clamp(0.5 + 0.5 * (shapeB.w - shapeA.w) / t, 0.0, 1.0);
    float shape = lerp(shapeB.w, shapeA.w, h) - t * h * (1.0 - h);
    float3 color = lerp(shapeB.rgb, shapeA.rgb, h);
    
    return float4(color, shape);
}
/// @param shapeA First shape color and SDF value (XYZ = RGB color, W = SDF value)
/// @param shapeB Second shape color and SDF value (XYZ = RGB color, W = SDF value)
/// @param t Smooth interpolation value (0.0 to 1.0)
/// @return Color and SDF value of the shapes smoothed union (XYZ = RGB color, W = SDF value)
inline float4 opSmoothUnionX4(float4 shapeA, float4 shapeB, float t)
{
    // Different way of getting smoothed min, t is also multiplied by 4 
    t *= 4.0;
    float h = max(t - abs(shapeA.w - shapeB.w), 0.0);
    float shape = min(shapeA.w, shapeB.w) - h * h * 0.25 / t;
    float3 color = lerp(shapeB.rgb, shapeA.rgb, h);
    
    return float4(color, shape);
}

/// Substraction
/// - Note: subtracted item depends on the order, produce only exterior sdf
/// @param shapeToSubtract SDF value of the shape that will subtract from the other shape
/// @param otherShape Color and SDF value of the shape that will be subtracted (XYZ = RGB color, W = SDF value)
/// @return Color and SDF value of the shapes subtraction (XYZ = RGB color, W = SDF value)
inline float4 opSubtraction(float shapeToSubtract, float4 otherShape)
{
    float shape = max(-shapeToSubtract, otherShape.w);
    float3 color = otherShape.rgb;
    
    return float4(color, shape);
}

/// Smooth Substraction
/// @param shapeToSubtract SDF value of the shape that will subtract from the other shape
/// @param otherShape Color and SDF value of the shape that will be subtracted (XYZ = RGB color, W = SDF value)
/// @param t Smooth interpolation value (0.0 to 1.0)
/// @return Color and SDF value of the shapes smoothed subtraction (XYZ = RGB color, W = SDF value)
inline float4 opSmoothSubtraction(float shapeToSubtract, float4 otherShape, float t)
{
    float shape = -opSmoothUnion(shapeToSubtract, -otherShape.w, t);
    float3 color = otherShape.rgb;
        
    return float4(color, shape);
}

/// Intersection
/// - Note: produce only exterior sdf
/// @param shapeA First shape color and SDF value (XYZ = RGB color, W = SDF value)
/// @param shapeB Second shape SDF value
/// @return Color and SDF value of the shapes intersection (XYZ = RGB color, W = SDF value)
inline float4 opIntersection(float4 shapeA, float shapeB)
{
    float shape = max(shapeA.w, shapeB);
    float3 color = shapeA.rgb;
    
    return float4(color, shape);
}

/// Smooth Intersection
/// @param shapeA First shape color and SDF value (XYZ = RGB color, W = SDF value)
/// @param shapeB Second shape SDF value
/// @param t Smooth interpolation value (0.0 to 1.0)
/// @return Color and SDF value of the shapes smoothed intersection (XYZ = RGB color, W = SDF value)
inline float4 opSmoothIntersection(float4 shapeA, float shapeB, float t)
{
    float shape = -opSmoothUnion(-shapeA.w, -shapeB, t);
    float3 color = shapeA.rgb;
    
    return float4(color, shape);
}

/// XOR (Exclusive OR: render only the areas where they not overlap)
/// - Note: produce true sdf (exterior and interior)
/// @param shapeA First shape color and SDF value (XYZ = RGB color, W = SDF value)
/// @param shapeB Second shape color and SDF value (XYZ = RGB color, W = SDF value)
/// @return Color and SDF value of the shapes XOR operation (XYZ = RGB color, W = SDF value)
inline float4 opXor(float4 shapeA, float4 shapeB)
{
    float shape = max(min(shapeA, shapeB), -max(shapeA, shapeB));
    float3 color = shape == shapeA.w ? shapeA.rgb : shapeB.rgb;
    
    return float4(color, shape);
}



// ---------------------
// ----- TRANSFORM -----
// ---------------------

inline float3 opMove(float3 rayPos, float3 newPos)
{
    return rayPos - newPos;
}

/// Rotate with XYZ angle value in radians
/// @param pos Position of the shape
/// @param rotation XYZ Rotations angle in radians
/// @return Position of the rotated shape
inline float3 opRotate(float3 pos, float3 rotation)
{
    float cx = cos(rotation.x);
    float sx = sin(rotation.x);
    float cy = cos(rotation.y);
    float sy = sin(rotation.y);
    float cz = cos(rotation.z);
    float sz = sin(rotation.z);
    
    float3x3 rotMatrix = float3x3(
        cy * cz,                 cy * sz,                 -sy,
        sx * sy * cz - cx * sz,  sx * sy * sz + cx * cz,  sx * cy,
        cx * sy * cz + sx * sz,  cx * sy * sz - sx * cz,  cx * cy
    );
    
    return mul(rotMatrix, pos);
}

/// Rotate with XYZ angle value in degrees
/// @param pos Position of the shape
/// @param rotation XYZ Rotations angle in degrees
/// @return Position of the rotated shape
inline float3 opRotateInDegree(float3 pos, float3 rotation)
{
    float xRot = radians(rotation.x);
    float yRot = radians(rotation.y);
    float zRot = radians(rotation.z);
    
    return opRotate(pos, float3(xRot, yRot, zRot));
}

/// Rotate with a 3x3 matrix representing a rotation matrix
/// @param pos Position of the shape
/// @param rotationMatrix Rotation matrix to use to rotate object
/// @return Position of the rotated shape
inline float3 opRotateWithMatrix(float3 pos, float3x3 rotationMatrix)
{
    return mul(rotationMatrix, pos);
}

/// Scale
/// @param pos Position of the shape
/// @param scaleFactor Scale factor to increase/decrease object size
/// @return XYZ: input position to create scaled shape, W: must multiply the SDF value of the scaled shape (shape(opScale.xyz) * opScale.w)
inline float4 opScale( in float3 pos, in float scaleFactor)
{
    return float4(pos/scaleFactor, scaleFactor);
}



// -------------------------
// ----- MODIFY 3D SDF -----
// -------------------------

/// Infinite Repetition
/// @param pos Position of the shape we want to repeat
/// @param repeatInterval Interval between every repetition of the SDF  
/// @return Position of the repeated shape
inline float3 opRepetition(in float3 pos, in float3 repeatInterval)
{
    return pos - repeatInterval * round(pos / repeatInterval);
}

/// Limited Repetition
/// @param pos Position of the shape we want to repeat
/// @param repeatInterval Interval between every repetition of the SDF  
/// @param repeatCount Number of shapes to repeat on every axis
/// @return Position of the repeated shape
float3 opRepetition(in float3 pos, in float repeatInterval, in float3 repeatCount)
{
    return pos - repeatInterval * clamp(round(pos / repeatInterval), -repeatCount, repeatCount);
}

/// Repetition along an axis: allow to repeat sdf along an axis
/// @param pos Position of the shape on the axis where we want to repeat the shape
/// @param repeatInterval Interval between every repetition of the SDF  
/// @return Modify input position to repeat the shape on an axis
inline float opRepetitionOnOneAxis(inout float pos, float repeatInterval)
{
    float halfSize = repeatInterval * 0.5;
    float c = floor((pos + halfSize) / repeatInterval);
    pos = fmod(pos + halfSize, repeatInterval) - halfSize;
    pos = fmod(-pos + halfSize, repeatInterval) - halfSize;
    
    return c;
}

/// Symmetry
/// @param pos Position of the shape
/// @param axis Symmetry axis
/// @return Position of the symmetrized shape: you must offset the shape from this position to see the symmetry
inline float3 opSymmetry(in float3 pos, int axis = SDF_AXIS_X)
{
    if (axis == SDF_AXIS_Y) pos.y = abs(pos.y);
    else if (axis == SDF_AXIS_Z) pos.z = abs(pos.z);
    else pos.x = abs(pos.x); // default is X axis
    
    return pos;
}

/// Symmetry on 2 axis
/// @param pos Position of the shape
/// @param axisA Symmetry plane first axis
/// @param axisB Symmetry plane second axis
/// @return Position of the symmetrized shape
inline float3 opSymmetry2Axis(in float3 pos, int axisA = SDF_AXIS_X, int axisB = SDF_AXIS_Z)
{
    if (axisA == SDF_AXIS_X || axisB == SDF_AXIS_X) pos.x = abs(pos.x);
    
    if (axisA == SDF_AXIS_Y || axisB == SDF_AXIS_Y) pos.y = abs(pos.y);
    
    if (axisA == SDF_AXIS_Z || axisB == SDF_AXIS_Z) pos.z = abs(pos.z);
    
    return pos;
}

/// Cut
/// @param sdf SDF value of the shape to cut
/// @param cutPos Position of the axis we want to use for the cut (pos.x, pos.y, pos.z). Negate the value to inverse the cut direction.
/// @param cutOffset Offset to move the cut along the object (min=-radius and max=radius)
/// @return SDF value of the cut object
inline float opCut(float sdf, float cutPos, float cutOffset = 0)
{
    return max(sdf, cutPos - cutOffset);
}

/// Plane Cut
/// @param sdf SDF value of the shape to cut
/// @param planePos Position of the plane that will represent the cut
/// @param planeNormal Normal of the plane that will represent the cut
/// @return SDF value of the cut object
inline float opCutPlane(float sdf, float3 planePos, float3 planeNormal)
{
    float planeCut = sdfPlane(planePos, planeNormal);
    return opCut(sdf, planeCut);
}

/// Round
/// @param sdf SDF value of the 3D shape we want to round
/// @param radius Radius of the rounding
/// @return SDF value of the rounded shape
inline float opRound(in float sdf, in float radius)
{
    return sdf - radius;
}

/// Elongate shape: apply to position before creating the shape (work best for 1D elongation, with 2D/3D elongations exterior and interior distance are not exact)
/// @param pos Position of the shape
/// @param xyzElongation Elongation value on XYZ axis
/// @return Position of the elongated shape
inline float3 opElongate1D(in float3 pos, in float3 xyzElongation)
{
    return pos - clamp( pos, -xyzElongation, xyzElongation );
}

/// Elongate shape: apply to position before creating the shape (give exact exterior and interior distance even with 2D/3D elongations)
/// @param pos Position of the shape
/// @param xyzElongation Elongation value on XYZ axis
/// @return XYZ: input position to create elongated shape, W: must be added to the SDF value of the elongated shape (shape(opElongate.xyz) + opElongate.w)
inline float4 opElongate( in float3 pos, in float3 xyzElongation)
{
    float3 q = abs(pos)-xyzElongation;
    return float4(max(q, 0.0), min(max(q.x, max(q.y, q.z)), 0.0));
}

/// Onion: Create onion-like edge pattern inside the object
/// @param sdf SDF value of the 3D shape we want to onion
/// @param thickness Thickness of the onion layer
/// @return SDF value of the onioned shape
inline float opOnion(in float sdf, in float thickness)
{
    return abs(sdf) - thickness;
}

/// Twist
/// @param pos Position of the shape
/// @param twistForce Intensity of the twist deformation
/// @return Position of the twisted shape
inline float3 opTwist(in float3 pos, float twistForce = 10.0)
{
    float c = cos(twistForce * pos.y);
    float s = sin(twistForce * pos.y);
    float2x2  twistMatrix = float2x2(c, -s, s, c);
    float3 twistedPos = float3(mul(twistMatrix, pos.xz), pos.y);
    return twistedPos;
}

/// Bend
/// @param pos Position of the shape
/// @param bendForce Intensity of the bend deformation
/// @return Position of the bent shape
inline float3 opBend(in float3 pos, float bendForce = 10.0)
{
    float c = cos(bendForce * pos.x);
    float s = sin(bendForce * pos.x);
    float2x2  bendMatrix = float2x2(c,-s,s,c);
    float3 bendPos = float3(mul(bendMatrix, pos.xy), pos.z);
    return bendPos;
}

// How to displace ?
// displacedShape = sdf + displacement function

/// Bubble displacement
/// @param pos Position of the shape
/// @param sdf Sdf value of the shape to displace
/// @param dispForce Intensity of the displacement
/// @return SDF value of the displaced shape
inline float opBubbleDisplacement(float3 pos, float sdf, float3 dispForce = 20)
{
    return sdf + sin(dispForce.x * pos.x) * sin(dispForce.y * pos.y) * sin(dispForce.z * pos.z);
}


