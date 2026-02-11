Shader "LearnShader/Sphere Tracing/Constructive Solid Geometry"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [KeywordEnum(HardShadow, SoftShadow)] _ShadowMode ("Shadow Mode", Float) = 0
        [KeywordEnum(NoReflections, CubemapReflections, FullReflections)] _ReflectionMode ("Reflections Mode", Float) = 0
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0 // Specify compile target, see https://docs.unity3d.com/2020.1/Documentation/Manual/SL-ShaderCompileTargets.html
            
            #pragma multi_compile_local _SHADOWMODE_HARDSHADOW _SHADOWMODE_SOFTSHADOW
            #pragma multi_compile_local _REFLECTIONMODE_NOREFLECTIONS _REFLECTIONMODE_CUBEMAPREFLECTIONS _REFLECTIONMODE_FULLREFLECTIONS
            
            // CG
            #include "UnityCG.cginc"
            // HLSL URP
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //#include "HLSLSupport.cginc"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            // SDF Functions
            #include "Assets/Shaders/SphereTracing/SDF_Functions.hlsl" // Cginc file that include all the SDF functions
            
            sampler2D _MainTex;
            uniform sampler2D _CameraDepthTexture;
            
            // Uniform variables we pass from c# script
            uniform float4x4 _CamFrustumMatrix;
            uniform float4x4 _CamToWorldMatrix;
            uniform float _MaxDistance;
            uniform uint _MaxIterations;
            uniform float _Accuracy;
            
            uniform fixed4 _GroundColor;
            uniform fixed4 _ShapesColors[8];
            uniform float _ColorIntensity;
            
            uniform float3 _LightColor;
            uniform float _LightIntensity;
            
            uniform float2 _ShadowDistance;
            uniform float _ShadowIntensity;
            uniform float _ShadowPenumbra;
            
            uniform float _AoStepSize;
            uniform int _AoIterations;
            uniform float _AoIntensity;
            
            uniform float _ReflectionCount;
            uniform float _ReflectionIntensity;
            uniform float _EnvReflectionIntensity;
            uniform samplerCUBE _ReflectionCube;
            
            // uniform float _ShapesInterpolation;
            // uniform float3 _RepeatInterval;
            // uniform float4 _Sphere1;
            // uniform float4 _Sphere2;
            // uniform float3 _BoxPosition;
            // uniform float3 _BoxSize;
            
            uniform bool _AnimateDemo;
            uniform float _AnimationSpeed;
            uniform float3 _DemoPos;
            uniform float3 _DemoRot;
            uniform float _DemoScale;
            uniform float _DemoSmooth;
            uniform float _DemoCutOffset;
            uniform float _DemoSymOffset;
            uniform float _DemoTwist;
            uniform float _DemoBend;
            uniform float _DemoDisplacement;
            
            uniform float4 _DebugParams;
            uniform int _DebugAxis;

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
                
                // CG
                o.vertex = UnityObjectToClipPos(v.vertex);
                // HLSL URP
                //o.vertex = TransformObjectToHClip(v.vertex);
                
                o.uv = v.uv;
                
                // Get Ray and convert to world space
                o.ray = _CamFrustumMatrix[(int)index].xyz;
                o.ray /= abs(o.ray.z); // Normalize ray in its Z direction
                o.ray = mul(_CamToWorldMatrix, o.ray); // convert to world-space
                
                return o;
            }
            
            float animate(float valueToAnimate)
            {
                return valueToAnimate * (_Time.y * _AnimationSpeed);
            }
            
            float animateSin(float min, float max)
            {
                float t = ((_SinTime.w * _AnimationSpeed)  + 1) / 2; // + 1 / 2 to remap from [-1,1] to [0,1]
                return lerp(min, max, t);
            }
            
            float animateCos(float min, float max)
            {
                float t = ((_CosTime.w * _AnimationSpeed)  + 1) / 2; // + 1 / 2 to remap from [-1,1] to [0,1]
                return lerp(min, max, t);
            }
            
            float4 distanceField(float3 rayPos)
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
                
                // Spheres
                float sphere = sdfSphere(rayPos - float3(0,0.5,0), 0.5);
                float cutSphere = sdfCutSphere(opRotateInDegree(rayPos - float3(0,0.5,2), float3(180,0,0)), 0.5, 0.5);
                float cutHollowSphere = sdfCutHollowSphere(rayPos - float3(0,0.5,4), 0.5, 0.25, 0.01);
                float deathStar = sdfDeathStar(opRotateInDegree(rayPos - float3(0,0.5,6), float3(0,45,0)), 0.5, 0.25, 0.5);
                
                float4 spheres = opUnion(float4(_ShapesColors[0].rgb, sphere), float4(_ShapesColors[1].rgb, cutSphere));
                spheres = opUnion(spheres, float4(_ShapesColors[2].rgb, cutHollowSphere));
                spheres = opUnion(spheres, float4(_ShapesColors[3].rgb, deathStar));
                
                // Boxes
                float box = sdfBox(rayPos - float3(2,0.5,0), float3(0.5,0.5,0.5));
                float roundBox = sdfRoundBox(rayPos - float3(2,0.5,2), float3(0.5,0.5,0.5), 0.2);
                float boxFrame = sdfBoxFrame(rayPos - float3(2,0.5,4), float3(0.5,0.5,0.5), 0.05);
                
                float4 boxes = opUnion(float4(_ShapesColors[0].rgb, box), float4(_ShapesColors[1].rgb, roundBox));
                boxes = opUnion(boxes, float4(_ShapesColors[2].rgb, boxFrame));
                
                // Plane
                float plane = sdfPlane(rayPos - float3(0,0,0), float3(0,1,0)); 
                
                // Tori
                float torus = sdfTorus(rayPos - float3(4,0.5,0), 0.5, 0.1);
                float cappedTorus = sdfCappedTorus(rayPos - float3(4,0.5,2), 0.5, 0.1, 0.75);
                float link = sdfLink(rayPos - float3(4,0.5,4), 0.5, 0.5, 0.1, SDF_AXIS_Y);
                
                float4 tori = opUnion(float4(_ShapesColors[0].rgb, torus), float4(_ShapesColors[1].rgb, cappedTorus));
                tori = opUnion(tori,  float4(_ShapesColors[2].rgb, link));
                
                // Cylinder
                float cylinderAxis = sdfCylinderAxis(rayPos - float3(6,0.5,0), 0.5, 0.25);
                float cylinder = sdfCylinder(rayPos - float3(6,0.5,2), float3(-0.225,-0.445,0), float3(0.225,0.445,0), 0.25);
                float roundedCylinder = sdfRoundedCylinder(rayPos - float3(6,0.5,4), 0.5, 0.25, 0.1);
                float infCylinder = sdfInfiniteCylinder(rayPos - float3(6,0.5,6), 0.25);
                
                float4 cylinders = opUnion(float4(_ShapesColors[1].rgb, cylinder), float4(_ShapesColors[0].rgb, cylinderAxis));
                cylinders = opUnion(cylinders, float4(_ShapesColors[2].rgb, roundedCylinder));
                cylinders = opUnion(cylinders, float4(_ShapesColors[3].rgb, infCylinder));
                
                // Cones
                float cone = sdfCone(rayPos - float3(8,1,0), 0.5, 1); // Y offset is 1 instead of 0.5 because origin is the tip of the cone
                float cappedConeAxis = sdfCappedConeAxis(rayPos - float3(8,0.5,2), 0.5, 0.5, 0.1);
                float cappedCone = sdfCappedCone(rayPos - float3(8,0.5,4), float3(-0.225,-0.445,0), float3(0.225,0.445,0), 0.5, 0.1); // start/end offset: => normalize(float3(0.25,0.5,0)) * 0.5
                float roundConeAxis = sdfRoundConeAxis(rayPos - float3(8,0.25,6), 0.65, 0.25, 0.1); // Y offset is 0.25 because we subtract the base radius
                float roundCone = sdfRoundCone(rayPos - float3(8,0.25,8), float3(0,0,0), float3(0,0.75,-0.75), 0.25, 0.1); // Y offset is 0.25 because we subtract the base radius
                float infiniteCone = sdfInfiniteCone(rayPos - float3(8,10,10), float2(sin(radians(2.5)), cos(radians(2.5))));
                
                float4 cones = opUnion(float4(_ShapesColors[0].rgb, cone), float4(_ShapesColors[1].rgb, cappedConeAxis));
                cones = opUnion(cones, float4(_ShapesColors[2].rgb, cappedCone));
                cones = opUnion(cones, float4(_ShapesColors[3].rgb, roundConeAxis));
                cones = opUnion(cones, float4(_ShapesColors[4].rgb, roundCone));
                cones = opUnion(cones, float4(_ShapesColors[5].rgb, infiniteCone));
                
                // Capsules
                float capsuleAxis = sdfCapsuleAxis(rayPos - float3(10,0.25,0), 0.5, 0.25); // Y offset is 0.25 because we subtract the base radius
                float capsule = sdfCapsule(rayPos - float3(10,0.5,2), float3(-0.1125,-0.2225, 0), float3(0.1125,0.2225, 0), 0.25); // start/end offset: normalize(float3(0.25,0.5,0)) * 0.25 (0.25 because we add 0.25 of radius after)
                
                float4 capsules = opUnion(float4(_ShapesColors[0].rgb, capsuleAxis), float4(_ShapesColors[1].rgb, capsule));
                
                // Polygonal Shapes
                float triangleSdf = sdfTriangle(rayPos - float3(12,0.5,0), float3(-0.5,-0.5,0), float3(0,0.5,0.5), float3(0.5,-0.5,0));
                float quad = sdfQuad(rayPos - float3(12,0.5,2), float3(-0.5,-0.5,0), float3(-0.5,0.5,0.5), float3(0.5,0.5,0.5), float3(0.5,-0.5,0));
                float pyramid = sdfPyramid(rayPos - float3(12,0,4), 1); // origin is a the bottom of the pyramid so no need to offset to place on the floor
                float octahedron = sdfOctahedron(rayPos - float3(11.4,0.5,6), 0.5);
                float octahedronBound = sdfOctahedronBound(rayPos - float3(12.6,0.5,6), 0.5);
                float rhombus = sdfRhombus(opRotateInDegree(rayPos - float3(12,0.6,8), float3(90,0,0)), 0.5, 0.2, 0.25, 0.2);
                float trianglePrism = sdfTrianglePrism(rayPos - float3(12,0.5,10), 0.75, 0.25);
                float hexPrism = sdfHexPrism(rayPos - float3(12,0.75,12), 0.75, 0.25); // Y offset is 0.75 to place the hexagon on the plane because radius is 0.75
                
                float4 polygons = opUnion(float4(_ShapesColors[0].rgb, triangleSdf), float4(_ShapesColors[1].rgb, quad));
                polygons = opUnion(polygons, float4(_ShapesColors[2].rgb, pyramid));
                polygons = opUnion(polygons, float4(_ShapesColors[3].rgb, octahedron));
                polygons = opUnion(polygons, float4(_ShapesColors[4].rgb, octahedronBound));
                polygons = opUnion(polygons, float4(_ShapesColors[5].rgb, rhombus));
                polygons = opUnion(polygons, float4(_ShapesColors[6].rgb, trianglePrism));
                polygons = opUnion(polygons, float4(_ShapesColors[7].rgb, hexPrism));
                
                // Other shapes
                float solidAngle = sdfSolidAngle(rayPos - float3(14,0,0), radians(45), 0.5);
                float vesica = sdfVesicaSegment(rayPos - float3(14,0.5,2), float3(-0.5,0,0), float3(0.5,0,0), 0.25);
                float ellipsoid = sdfEllipsoid(rayPos - float3(14,0.5,4), float3(0.5, 0.25, 0.25));
                
                float4 otherShapes = opUnion(float4(_ShapesColors[0].rgb, solidAngle), float4(_ShapesColors[1].rgb, vesica));
                otherShapes = opUnion(otherShapes, float4(_ShapesColors[2].rgb, ellipsoid));
                
                // Transform
                float3 position = _AnimateDemo ? _DemoPos + float3(animateSin(-0.25,0.25), 0, animateCos(-0.25,0.25)) : _DemoPos;
                float3 movePos = opMove(rayPos, position);
                float moveCube = sdfBox(movePos, 0.3);
                
                float3 rotation = _AnimateDemo ? float3(_DemoRot.x, animate(_DemoRot.y), _DemoRot.z) : _DemoRot;
                //float3 rotPos = opRotateInDegree(rayPos - float3(3,0.5,-2), _DemoRot);
                float3 rotPos = opRotateInDegree(rayPos - float3(3,0.5,-2), rotation);
                float rotCube = sdfBox(rotPos, 0.3);
                
                float scale = _AnimateDemo ? _DemoScale + animateSin(0,0.25) : _DemoScale;
                float4 scaledPos = opScale(rayPos - float3(4,0.5,-2.5), scale);
                float scaledBox = sdfBox(scaledPos.xyz, 0.5) * scaledPos.w;

                float4 transformShapes = opUnion(float4(_ShapesColors[0].rgb, moveCube), float4(_ShapesColors[1].rgb, rotCube));
                transformShapes = opUnion(transformShapes, float4(_ShapesColors[2].rgb, scaledBox));
                
                // Combine shapes
                float smooth = _AnimateDemo ? saturate(_DemoSmooth + animateSin(-0.05,0.05)) : _DemoSmooth; // To animate smooth, not used for now
                float3 posAnimOffset = _AnimateDemo ? float3(0,animateCos(-0.15,0.1),0) : float3(0,0,0);
                
                float cubeU = sdfBox(rayPos - float3(5,0.5,-3), 0.3);
                float sphereU = sdfSphere(rayPos - float3(5,0.9,-3) - posAnimOffset, 0.25);
                float Union = opUnion(cubeU, sphereU);
                
                float cubeSU = sdfBox(rayPos - float3(5,0.5,-2), 0.3);
                float sphereSU = sdfSphere(rayPos - float3(5,0.9,-2) - posAnimOffset, 0.25);
                float smoothUnion = opSmoothUnion(cubeSU, sphereSU, _DemoSmooth);
                
                float cubeSub = sdfBox(rayPos - float3(6,0.5,-3), 0.3);
                float sphereSub = sdfSphere(rayPos - float3(6,0.9,-3) - posAnimOffset, 0.25);
                float subtract = opSubtraction(sphereSub,cubeSub);
                
                float cubeSSub = sdfBox(rayPos - float3(6,0.5,-2), 0.3);
                float sphereSSub = sdfSphere(rayPos - float3(6,0.9,-2) - posAnimOffset, 0.25);
                float smoothSub = opSmoothSubtraction(sphereSSub, cubeSSub, _DemoSmooth);
                
                float cubeInt = sdfBox(rayPos - float3(7,0.5,-3), 0.3);
                float sphereInt = sdfSphere(rayPos - float3(7,0.9,-3) - posAnimOffset, 0.25);
                float intersect = opIntersection(cubeInt,sphereInt);
                
                float cubeSInt = sdfBox(rayPos - float3(7,0.5,-2), 0.3);
                float sphereSInt = sdfSphere(rayPos - float3(7,0.9,-2) - posAnimOffset, 0.25);
                float smoothInt = opSmoothIntersection(cubeSInt, sphereSInt, _DemoSmooth);
                
                float cubeNoXOR = sdfBox(rayPos - float3(8,0.5,-3), 0.3);
                float sphereNoXOR = sdfSphere(rayPos - float3(8,0.9,-3) - posAnimOffset, 0.25);
                float noXOR = opCutPlane(opUnion(cubeNoXOR, sphereNoXOR), rayPos - float3(8,0.5,-3), float3(0,0,-1));
                
                float cubeXOR = sdfBox(rayPos - float3(8,0.5,-2), 0.3);
                float sphereXOR = sdfSphere(rayPos - float3(8,0.9,-2) - posAnimOffset, 0.25);
                float xOR = opCutPlane(opXor(cubeXOR, sphereXOR), rayPos - float3(8,0.5,-2), float3(0,0,-1));
                
                float4 combinedShapes = opUnion(float4(_ShapesColors[0].rgb, Union), float4(_ShapesColors[1].rgb, smoothUnion));
                combinedShapes = opUnion(combinedShapes, float4(_ShapesColors[2].rgb, subtract));
                combinedShapes = opUnion(combinedShapes, float4(_ShapesColors[3].rgb, smoothSub));
                combinedShapes = opUnion(combinedShapes, float4(_ShapesColors[4].rgb, intersect));
                combinedShapes = opUnion(combinedShapes, float4(_ShapesColors[5].rgb, smoothInt));
                combinedShapes = opUnion(combinedShapes, float4(_ShapesColors[6].rgb, xOR));
                combinedShapes = opUnion(combinedShapes, float4(_ShapesColors[7].rgb, noXOR));
                
                // Repeat Shapes
                float interval1 = _AnimateDemo ? animateSin(0.6,0.8) : 0.8;
                float3 repeatPos1 = opRepetition(rayPos - float3(1,1.05,16), interval1, 1);
                float3 infiniteRepeatPos = opRepetition(rayPos - float3(1,1.05,16), interval1); // Infinite repetition
                float repeatBox = sdfBox(repeatPos1, 0.25);
                
                float interval2 = _AnimateDemo ? animateSin(0.65,0.75) : 0.75;
                float3 repeatPos2 = opMove(rayPos, float3(1,0.125,18));
                opRepetitionOnOneAxis(repeatPos2.y, interval2);
                float repeatSphere = sdfSphere(repeatPos2, 0.25);
                
                float4 repeats = opUnion(float4(_ShapesColors[0].rgb, repeatBox), float4(_ShapesColors[1].rgb, repeatSphere));
                
                // Cut
                float cutOffset = _AnimateDemo ? clamp(_DemoCutOffset + animateSin(-0.1,0.1), -0.25, 0.25) : _DemoCutOffset;
                float3 cutPos1 = rayPos - float3(3,0.5,15.5);
                float cutBox1 = sdfBox(cutPos1, 0.25);
                cutBox1 = opCut(cutBox1, cutPos1.y, cutOffset);
                
                float3 cutPos2 = rayPos - float3(3.6,0.5,15.5);
                float cutBox2 = sdfBox(cutPos2, 0.25);
                cutBox2 = opCut(cutBox2, -cutPos2.z, cutOffset);
                
                float3 cutPos3 = rayPos - float3(3.3,0.5,16.5);
                float cutBox3 = sdfBox(cutPos3, 0.5);
                cutBox3 = opCutPlane(cutBox3, cutPos3 - float3(0,cutOffset * 4,0), normalize(float3(0,1,-1)));
                
                float4 cuts = opUnion(float4(_ShapesColors[0].rgb, cutBox1), float4(_ShapesColors[1].rgb, cutBox2));
                cuts = opUnion(cuts,float4(_ShapesColors[2].rgb, cutBox3));
                
                // Round shape
                float roundOcta = sdfOctahedron(rayPos - float3(4.75,0.5,16), 0.35);
                roundOcta = opRound(roundOcta, _AnimateDemo ? 0.125 + animateSin(-0.1,0.1) : 0.125);
                
                // Elongate
                float3 elong1 = _AnimateDemo ? float3(0,0,0.25 + animateSin(-0.1,0.1)) : float3(0,0,0.25);
                float3 elongPos1 = opElongate1D(rayPos - float3(6,0.8,15.5), elong1);
                float elongTorus = sdfTorus(elongPos1, 0.35, 0.05, SDF_AXIS_Z);
                float3 elong2 = _AnimateDemo ? float3(0,0.5 + animateSin(-0.2,0.1),0) : float3(0,0.5,0);
                float4 elongPos2 = opElongate(rayPos - float3(6,0.8,16.5), elong2);
                float elongOcta = sdfOctahedron(elongPos2.xyz, 0.35) + elongPos2.w;
                
                float4 elongatedShapes = opUnion(float4(_ShapesColors[0].rgb, elongOcta), float4(_ShapesColors[1].rgb, elongTorus));
                
                // Onion
                float3 onionPos1 = rayPos - float3(7,0.5,15.5);
                float sphereToOnion = sdfSphere(onionPos1, 0.25);
                float onionSphere = opCut(opOnion(opOnion(opOnion(sphereToOnion, 0.06), 0.03), 0.01), onionPos1.y); // opCut(sdf, pos.y) to be able to see sdf interior
                float3 onionPos2 = rayPos - float3(7,0.5,16.5);
                float boxToOnion = sdfBox(onionPos2, 0.25);
                float onionBox = opCut(opOnion(opOnion(opOnion(boxToOnion, 0.06), 0.03), 0.01), onionPos2.y); // opCut(sdf, pos.y) to be able to see sdf interior
                
                float4 onions = opUnion(float4(_ShapesColors[0].rgb, onionSphere), float4(_ShapesColors[1].rgb, onionBox)); 
                
                // Symmetry
                float symOffset = _AnimateDemo ? _DemoSymOffset + animateCos(-0.2,0.2) : _DemoSymOffset;
                
                float3 symPosX = opSymmetry(rayPos - float3(8.5,0.75,15.5), SDF_AXIS_X);
                float3 symXOffset = float3(symOffset,0,0);
                float symXCone = sdfCappedConeAxis(symPosX - symXOffset, 0.25, 0.25,0.1);
                
                float3 symPosZ = opSymmetry(rayPos - float3(8.5,0.75,16.5), SDF_AXIS_Z);
                float3 symZOffset = float3(0,0,symOffset);
                float symZCone = sdfCappedConeAxis(symPosZ - symZOffset, 0.25, 0.25,0.1);
                
                float3 sym2AxisPos = opSymmetry2Axis(rayPos - float3(8.5,0.75,17.5), SDF_AXIS_X, SDF_AXIS_Y);
                float3 sym2AxisOffset = float3(symOffset,symOffset,0);
                float sym2AxisCone = sdfCappedConeAxis(sym2AxisPos - sym2AxisOffset, 0.25, 0.25,0.1);
                
                float4 symmetries = opUnion(float4(_ShapesColors[0].rgb, symXCone), float4(_ShapesColors[1].rgb, symZCone));
                symmetries = opUnion(symmetries, float4(_ShapesColors[2].rgb, sym2AxisCone));
                
                // Twist
                float twist = _AnimateDemo ? _DemoTwist + animateSin(-2,1) : _DemoTwist;
                float3 twistPos1 = opTwist(rayPos - float3(10,0.5,15.5), twist);
                float twistedTorus = sdfTorus(twistPos1, 0.35, 0.05, SDF_AXIS_Y);
                float3 twistPos2 = opTwist(rayPos - float3(10,0.5,16.5), twist);
                float twistedBox = sdfBoxFrame(twistPos2, 0.3, 0.04);
                
                float4 twistedShapes = opUnion(float4(_ShapesColors[0].rgb, twistedTorus), float4(_ShapesColors[1].rgb, twistedBox));
                    
                // Bend
                float bend = _AnimateDemo ? _DemoBend + animateCos(-2,0): _DemoBend;
                float3 bendPos1 = opBend(rayPos - float3(11.5,0.5,15.5), bend);
                float bendLink = sdfLink(bendPos1, 0.5, 0.25, 0.1, SDF_AXIS_Y);
                float3 bendPos2 = opBend(rayPos - float3(11.5,0.5,16.5), bend);
                float bendBox = sdfBox(bendPos2, float3(0.5,0.2,0.35));
                
                float4 bentShapes = opUnion(float4(_ShapesColors[1].rgb, bendBox), float4(_ShapesColors[0].rgb, bendLink));
                
                // Displacement
                float disp = _AnimateDemo ? _DemoDisplacement + animateSin(-0.5,0.5) : _DemoDisplacement;
                float3 dispPos = rayPos - float3(13.5,0.5,16);
                float dispSphere = sdfSphere(dispPos, 0.25);
                dispSphere = opBubbleDisplacement(dispPos, dispSphere, disp);
                
                // FINAL SHAPES COMBINATION
                float4 shapes = opUnion(spheres, boxes);
                shapes = opUnion(shapes, float4(_GroundColor.rgb, plane));
                shapes = opUnion(shapes, tori);
                shapes = opUnion(shapes, cylinders);
                shapes = opUnion(shapes, cones);
                shapes = opUnion(shapes, capsules);
                shapes = opUnion(shapes, polygons);
                shapes = opUnion(shapes, otherShapes);
                shapes = opUnion(shapes, transformShapes);
                shapes = opUnion(shapes, combinedShapes);
                shapes = opUnion(shapes, repeats);
                shapes = opUnion(shapes, cuts);
                shapes = opUnion(shapes, float4(_ShapesColors[0].rgb,roundOcta));
                shapes = opUnion(shapes, elongatedShapes);
                shapes = opUnion(shapes, onions);
                shapes = opUnion(shapes, symmetries);
                shapes = opUnion(shapes, twistedShapes);
                shapes = opUnion(shapes, bentShapes);
                shapes = opUnion(shapes, float4(_ShapesColors[0].rgb, dispSphere));
                
                return shapes;
            }
            
            float3 getNormal(float3 hitPos)
            {
                const float2 offset = float2(0.001, 0.0);
                float3 normal = float3(
                    distanceField(hitPos + offset.xyy).w - distanceField(hitPos - offset.xyy).w,
                    distanceField(hitPos + offset.yxy).w - distanceField(hitPos - offset.yxy).w,
                    distanceField(hitPos + offset.yyx).w - distanceField(hitPos - offset.yyx).w);
                
                return normalize(normal);
            }
            
            float hardShadows(float3 rayOrigin, float3 rayDirection, float minDist, float maxDist)
            {
                for (float d = minDist; d < maxDist;)
                {
                    float h = distanceField(rayOrigin + rayDirection * d).w;
                    if (h < 0.001)
                    {
                        return 0.0; // Shadow
                    }
                    d += h;
                }
                return 1.0; // No Shadow
            }
            
            float softShadow(float3 rayOrigin, float3 rayDirection, float minDist, float maxDist, float penumbra)
            {
                float result = 1.0;
                for (float d = minDist; d < maxDist;)
                {
                    float h = distanceField(rayOrigin + rayDirection * d).w;
                    if (h < 0.001)
                    {
                        return 0.0; // Shadow
                    }
                    result = min(result, penumbra * h / d);
                    d += h;
                }
                return result; // No Shadow
            }
            
            float3 ambientOcclusion(float3 pos, float3 normal)
            {
                float step = _AoStepSize;
                float ao = 0.0;
                float dist;
                
                for (int i = 1; i <= _AoIterations; i++)
                {
                    dist = step * i;
                    ao += max(0.0, (dist - distanceField(pos + normal * dist).w) / dist);
                }
                return (1.0 - ao * _AoIntensity);
            }
            
            float3 shading(float3 pos, float3 normal, fixed3 color)
            {
                float3 result;
                
                float3 col = color * _ColorIntensity;
                
                // CG
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                
                // HLSL URP
                //Light mainLight = GetMainLight();
                //float3 lightDir = mainLight.direction;
                
                // Directional light
                // -> dot product to know if the normal point toward the light or no
                // -> * 0.5 + 0.5 to prevent multiplication by 0
                float3 light = (_LightColor * dot(lightDir, normal) * 0.5 + 0.5) * _LightIntensity;
                
                // Shadows
                #if _SHADOWMODE_HARDSHADOW
                    float shadow = hardShadows(pos, lightDir, _ShadowDistance.x, _ShadowDistance.y) * 0.5 + 0.5;
                #elif _SHADOWMODE_SOFTSHADOW
                    float shadow = softShadow(pos, lightDir, _ShadowDistance.x, _ShadowDistance.y, _ShadowPenumbra) * 0.5 + 0.5;
                #endif
                shadow = max(0.0, pow(shadow, _ShadowIntensity));
                
                // Ambient occlusion
                float ao = ambientOcclusion(pos, normal);
                
                result = col * light * shadow * ao;
                
                return result;
            }
            
            bool raymarching(float3 rayOrigin, float3 rayDirection, float depth, float maxDistance, int maxIterations, inout float3 hitPos, inout fixed3 color)
            {
                bool hit;
                float dist = 0; // distance travelled along the ray direction

                for (int i = 0; i < maxIterations; i++)
                {
                    if (dist > maxDistance || dist >= depth) // Hit environment / skybox
                    {
                        hit = false;
                        break;
                    }
                    
                    hitPos = rayOrigin + rayDirection * dist;
                    float4 colorAndSdf = distanceField(hitPos); // Signed distance field (< 0 = inside something, > 0 outside something)
                    if (colorAndSdf.w < _Accuracy) // We hit something
                    {
                        color = colorAndSdf.rgb;
                        hit = true;
                        break;
                    }
                    dist += colorAndSdf.w;
                }
                return hit;
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                 // CG
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
                
                // HLSL URP: we need to the built-in varaible _ZBufferParams to the function
                //float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r, _ZBufferParams); // In HLSL we need to the built-in varaible _ZBufferParams to the function
                
                depth *= length(i.ray);
                
                fixed3 texColor = tex2D(_MainTex, i.uv);
                
                float3 rayDirection = normalize(i.ray.xyz);
                float3 rayOrigin = _WorldSpaceCameraPos;
                
                fixed4 result; 
                float3 hitPosition;
                fixed3 color;
                
                // Shape raymarching
                bool hit = raymarching(rayOrigin, rayDirection, depth, _MaxDistance, _MaxIterations, hitPosition, color);
                
                if (hit)
                {
                    // Shade object
                    float3 normal =  getNormal(hitPosition);
                    float3 shade = shading(hitPosition, normal, color);
                    result = fixed4(shade, 1) ;
                    
                    // Cubemap reflections
                    #if _REFLECTIONMODE_CUBEMAPREFLECTIONS || _REFLECTIONMODE_FULLREFLECTIONS
                    result += fixed4(texCUBE(_ReflectionCube, normal).rgb * _EnvReflectionIntensity * _ReflectionIntensity, 0);
                    #endif
                    
                    #if _REFLECTIONMODE_FULLREFLECTIONS
                    // Reflections
                    if (_ReflectionCount > 0)
                    {
                        rayDirection = normalize(reflect(rayDirection, normal));
                        rayOrigin = hitPosition + (rayDirection * 0.01);
                        
                        // Raymarching to get other sdf shapes reflections
                        // -> depth buffer is ignored so we replace it with _MaxDistance
                        // _MaxDistance and iterations are divided by 2
                        hit = raymarching(rayOrigin, rayDirection, _MaxDistance, _MaxDistance * 0.5f, _MaxIterations / 2, hitPosition, color);
                        
                        if (hit)
                        {
                            float3 normal =  getNormal(hitPosition);
                            float3 shade = shading(hitPosition, normal, color);
                            result += fixed4(shade * _ReflectionIntensity, 0);
                            if (_ReflectionCount > 1)
                            {
                                rayDirection = normalize(reflect(rayDirection, normal));
                                rayOrigin = hitPosition + (rayDirection * 0.01);
                                
                                // Raymarching to get reflections inside other sdf shapes reflections
                                hit = raymarching(rayOrigin, rayDirection, _MaxDistance, _MaxDistance * 0.25f, _MaxIterations / 4, hitPosition, color); // Divided by 4
                                
                                if (hit)
                                {
                                    float3 normal =  getNormal(hitPosition);
                                    float3 shade = shading(hitPosition, normal, color);
                                    result += fixed4(shade * _ReflectionIntensity * 0.5f, 0);
                                }
                            }
                        }
                    }
                    #endif
                    
                }
                else
                {
                    result = fixed4(0,0,0,0);
                }

                return fixed4(texColor * (1.0 - result.w) + result.rgb * result.w  ,1.0); // Draw scene + rayMarched shapes
            }
            ENDHLSL
        }
    }
}
