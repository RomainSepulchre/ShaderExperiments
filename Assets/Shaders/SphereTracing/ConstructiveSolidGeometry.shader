Shader "LearnShader/Sphere Tracing/Constructive Solid Geometry"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0 // Specify compile target, see https://docs.unity3d.com/2020.1/Documentation/Manual/SL-ShaderCompileTargets.html

            #include "UnityCG.cginc"
            #include "Assets/Shaders/SphereTracing/SDF_Functions.cginc" // Cginc file that include all the SDF functions
            
            sampler2D _MainTex;
            uniform sampler2D _CameraDepthTexture;
            
            // Uniform variables we pass from c# script
            uniform float4x4 _CamFrustumMatrix;
            uniform float4x4 _CamToWorldMatrix;
            uniform float _MaxDistance;
            uniform fixed4 _ShapesColor;
            uniform float _ShapesInterpolation;
            uniform float3 _RepeatInterval;
            uniform float4 _Sphere1;
            uniform float4 _Sphere2;
            uniform float3 _BoxPosition;
            uniform float3 _BoxSize;
            uniform float3 _DebugPos;
            uniform float4 _DebugParams;
            uniform int _DebugAxis;
            uniform float3 _DebugRot;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray : TEXCOORD1; // store ray direction
            };

            v2f vert (appdata v)
            {
                v2f o;
                
                // Get index for frustum matrix
                half index = v.vertex.z;
                v.vertex.z = 0;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                
                // Get Ray and convert to world space
                o.ray = _CamFrustumMatrix[(int)index].xyz;
                o.ray /= abs(o.ray.z); // Normalize ray in its Z direction
                o.ray = mul(_CamToWorldMatrix, o.ray); // convert to world-space
                
                return o;
            }
            
            float smoothMinimum(float a, float b, float t) // Moved into SDF_Functions.cginc as opSmoothedUnion()
            {
                float h = clamp(0.5 + 0.5 * (b - a) / t, 0.0, 1.0);
                return lerp(b, a, h) - t * h * (1.0 - h);
            }
            
            float distanceField(float3 rayPos)
            {
                // Repeat shapes
                //float modX = pMod1(rayPos.x, _RepeatInterval.x);
                //float modY = pMod1(rayPos.y, _RepeatInterval.y);
                //float modZ = pMod1(rayPos.z, _RepeatInterval.z);
                
                // Shapes to draw
                // float sphere1 = sdfSphere(rayPos - _Sphere1.xyz, _Sphere1.w);
                // float sphere2 = sdfSphere(rayPos - _Sphere2.xyz, _Sphere2.w);
                // float box = sdfBox(rayPos - _BoxPosition, _BoxSize);
                
                // Merged shapes
                // float smoothedShapes = opSmoothUnion(sphere1, sphere2, _ShapesInterpolation);
                // float smoothedIntersection = opSmoothIntersection(sphere1, box, _ShapesInterpolation);
                // float mergedShapes = opSmoothSubtraction(sphere1, box, _ShapesInterpolation);
                
                // Test the shapes
                float3 pos = opMove(rayPos, _DebugPos);
                
                // Spheres
                float sphere = sdfSphere(rayPos - float3(0,0.5,0), 0.5);
                float cutSphere = sdfCutSphere(opRotateInDegree(rayPos - float3(0,0.5,2), float3(180,0,0)), 0.5, 0.5);
                float cutHollowSphere = sdfCutHollowSphere(rayPos - float3(0,0.5,4), 0.5, 0.25, 0.01);
                float deathStar = sdfDeathStar(opRotateInDegree(rayPos - float3(0,0.5,6), float3(0,45,0)), 0.5, 0.25, 0.5);
                
                float spheres = opUnion(sphere, cutSphere);
                spheres = opUnion(spheres, cutHollowSphere);
                spheres = opUnion(spheres, deathStar);
                
                // Boxes
                float box = sdfBox(rayPos - float3(2,0.5,0), float3(0.5,0.5,0.5));
                float roundBox = sdfRoundBox(rayPos - float3(2,0.5,2), float3(0.5,0.5,0.5), 0.2);
                float boxFrame = sdfBoxFrame(rayPos - float3(2,0.5,4), float3(0.5,0.5,0.5), 0.05);
                
                float boxes = opUnion(box, roundBox);
                boxes = opUnion(boxes, boxFrame);
                
                // Plane
                float plane = sdfPlane(rayPos - float3(0,0,0), float3(0,1,0)); 
                
                // Tori
                float torus = sdfTorus(rayPos - float3(4,0.5,0), 0.5, 0.1);
                float cappedTorus = sdfCappedTorus(rayPos - float3(4,0.5,2), 0.5, 0.1, 0.75);
                float link = sdfLink(rayPos - float3(4,0.5,4), 0.5, 0.5, 0.1, _DebugAxis);
                
                float tori = opUnion(torus, cappedTorus);
                tori = opUnion(tori, link);
                
                // Cylinder
                float cylinderAxis = sdfCylinderAxis(rayPos - float3(6,0.5,0), 0.5, 0.25);
                float cylinder = sdfCylinder(rayPos - float3(6,0.5,2), float3(-0.225,-0.445,0), float3(0.225,0.445,0), 0.25);
                float roundedCylinder = sdfRoundedCylinder(rayPos - float3(6,0.5,4), 0.5, 0.25, 0.1);
                float infCylinder = sdfInfiniteCylinder(rayPos - float3(6,0.5,6), 0.25);
                
                float cylinders = opUnion(cylinder, cylinderAxis);
                cylinders = opUnion(cylinders, roundedCylinder);
                cylinders = opUnion(cylinders, infCylinder);
                
                // Cones
                float cone = sdfCone(rayPos - float3(8,1,0), 0.5, 1); // Y offset is 1 instead of 0.5 because origin is the tip of the cone
                float cappedConeAxis = sdfCappedConeAxis(rayPos - float3(8,0.5,2), 0.5, 0.5, 0.1);
                float cappedCone = sdfCappedCone(rayPos - float3(8,0.5,4), float3(-0.225,-0.445,0), float3(0.225,0.445,0), 0.5, 0.1); // start/end offset: => normalize(float3(0.25,0.5,0)) * 0.5
                float roundConeAxis = sdfRoundConeAxis(rayPos - float3(8,0.25,6), 0.65, 0.25, 0.1); // Y offset is 0.25 because we subtract the base radius
                float roundCone = sdfRoundCone(rayPos - float3(8,0.25,8), float3(0,0,0), float3(0,0.75,-0.75), 0.25, 0.1); // Y offset is 0.25 because we subtract the base radius
                float infiniteCone = sdfInfiniteCone(rayPos - float3(8,10,10), float2(sin(radians(2.5)), cos(radians(2.5))));
                
                float cones = opUnion(cone, cappedConeAxis);
                cones = opUnion(cones, cappedCone);
                cones = opUnion(cones, roundConeAxis);
                cones = opUnion(cones, roundCone);
                cones = opUnion(cones, infiniteCone);
                
                // Capsules
                float capsuleAxis = sdfCapsuleAxis(rayPos - float3(10,0.25,0), 0.5, 0.25); // Y offset is 0.25 because we subtract the base radius
                float capsule = sdfCapsule(rayPos - float3(10,0.5,2), float3(-0.1125,-0.2225, 0), float3(0.1125,0.2225, 0), 0.25); // start/end offset: normalize(float3(0.25,0.5,0)) * 0.25 (0.25 because we add 0.25 of radius after)
                
                float capsules = opUnion(capsuleAxis, capsule);
                
                // Polygonal Shapes
                float triangleSdf = sdfTriangle(rayPos - float3(12,0.5,0), float3(-0.5,-0.5,0), float3(0,0.5,0.5), float3(0.5,-0.5,0));
                float quad = sdfQuad(rayPos - float3(12,0.5,2), float3(-0.5,-0.5,0), float3(-0.5,0.5,0.5), float3(0.5,0.5,0.5), float3(0.5,-0.5,0));
                float pyramid = sdfPyramid(rayPos - float3(12,0,4), 1); // origin is a the bottom of the pyramid so no need to offset to place on the floor
                float octahedron = sdfOctahedron(rayPos - float3(11.4,0.5,6), 0.5);
                float octahedronBound = sdfOctahedronBound(rayPos - float3(12.6,0.5,6), 0.5);
                float rhombus = sdfRhombus(opRotateInDegree(rayPos - float3(12,0.6,8), float3(90,0,0)), 0.5, 0.2, 0.25, 0.2);
                float trianglePrism = sdfTrianglePrism(rayPos - float3(12,0.5,10), 0.75, 0.25);
                float hexPrism = sdfHexPrism(rayPos - float3(12,0.75,12), 0.75, 0.25); // Y offset is 0.75 to place the hexagon on the plane because radius is 0.75
                
                float polygons = opUnion(triangleSdf, quad);
                polygons = opUnion(polygons, pyramid);
                polygons = opUnion(polygons, octahedron);
                polygons = opUnion(polygons, octahedronBound);
                polygons = opUnion(polygons, rhombus);
                polygons = opUnion(polygons, trianglePrism);
                polygons = opUnion(polygons, hexPrism);
                
                // Other shapes
                float solidAngle = sdfSolidAngle(rayPos - float3(14,0,0), radians(45), 0.5);
                float vesica = sdfVesicaSegment(rayPos - float3(14,0.5,2), float3(-0.5,0,0), float3(0.5,0,0), 0.25);
                float ellipsoid = sdfEllipsoid(rayPos - float3(14,0.5,4), float3(0.5, 0.25, 0.25));
                
                float otherShapes = opUnion(solidAngle, vesica);
                otherShapes = opUnion(otherShapes, ellipsoid);
                
                // FINAL SHAPES COMBINATION
                float shapes = opUnion(spheres, boxes);
                //shapes = opUnion(shapes, plane);
                shapes = opUnion(shapes, tori);
                shapes = opUnion(shapes, cylinders);
                shapes = opUnion(shapes, cones);
                shapes = opUnion(shapes, capsules);
                shapes = opUnion(shapes, polygons);
                shapes = opUnion(shapes, otherShapes);
                

                // Scale
                float4 scaledPos = opScale(pos, _DebugParams.w);
                float scaledSphere = sdfSphere(scaledPos.xyz, 0.5) * scaledPos.w;
                
                // Rotation
                float3 rotPos = opRotateInDegree(pos, _DebugRot);
                float rotBox = sdfBox(rotPos, float3(1,1,1));
                float rotSphere = sdfSphere(rotPos, 0.5);
                
                // Repeat
                float3 repeatedPos = opRepetition(rotPos, _RepeatInterval, float3(1,1,1));
                float repeatSphere = sdfSphere(repeatedPos, 0.25);
                
                // 
                float3 bendPos = opCheapBend(pos, _DebugParams.w);
                float3 twistPos = opTwist(pos, _DebugParams.w);
                float3 twistTorrus = sdfTorus(twistPos, 1,0.1, _DebugAxis);
                
                
                float dispTorrus = sdfTorus(pos, 1, 0.1, SDF_AXIS_Y);
                
                // Simple Onion sphere
                //float onionSphere = max(opOnion(opOnion(scaledSphere, _DebugParams.x), _DebugParams.y), pos.y); // max(sdf, pos.y) to be able to see sdf interior
                
                // Rotated onion
                float rotOnionSphere = max(opOnion(opOnion(opOnion(rotSphere, _DebugParams.x), _DebugParams.y), _DebugParams.z), rotPos.y);
                
                // Repeated onion
                float repeatOnionSphere = max(opOnion(opOnion(opOnion(repeatSphere, _DebugParams.x), _DebugParams.y), _DebugParams.z), repeatedPos.y);
                
                return shapes;
            }
            
            float3 getNormal(float3 hitPos)
            {
                const float2 offset = float2(0.001, 0.0);
                float3 normal = float3(
                    distanceField(hitPos + offset.xyy) - distanceField(hitPos - offset.xyy),
                    distanceField(hitPos + offset.yxy) - distanceField(hitPos - offset.yxy),
                    distanceField(hitPos + offset.yyx) - distanceField(hitPos - offset.yyx));
                
                return normalize(normal);
            }
            
            fixed4 raymarching(float3 rayOrigin, float3 rayDirection, float depth)
            {
                fixed4 result = fixed4(1,1,1,1);
                const int maxIteration = 64;
                float dist = 0; // distance travelled along the ray direction

                for (int i = 0; i < maxIteration; i++)
                {
                    if (dist > _MaxDistance || dist >= depth) // Hit environment / skybox
                    {
                        result = fixed4(rayDirection, 0); // w = 0 to tell when to draw screen render texture
                        break;
                    }
                    
                    float3 rayPos = rayOrigin + rayDirection * dist;
                    float sdf = distanceField(rayPos); // Signed distance field (< 0 = inside something, > 0 outside something)
                    if (sdf < 0.01) // We hit something
                    {
                        // Shade object
                        float3 normal =  getNormal(rayPos);
                        float3 lightDir = _WorldSpaceLightPos0.xyz;
                        float light = dot(lightDir, normal); // dot product to know if the normal point toward the light or no
                        result = fixed4(_ShapesColor.rgb * light, 1) ;
                        break;
                    }
                    dist += sdf;
                }
                return result;
            }

            fixed4 frag (v2f i) : SV_Target
            {                
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r); // Depth texture is all black
                depth *= length(i.ray);
                
                fixed3 texColor = tex2D(_MainTex, i.uv);
                
                float3 rayDirection = normalize(i.ray.xyz);
                float3 rayOrigin = _WorldSpaceCameraPos;
                fixed4 result = raymarching(rayOrigin, rayDirection, depth);
                
                return fixed4(texColor * (1.0 - result.w) + result.rgb * result.w  ,1.0); // Draw scene + rayMarched shapes
            }
            ENDCG
        }
    }
}
