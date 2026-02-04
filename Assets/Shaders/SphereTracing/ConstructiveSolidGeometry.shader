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
                float sphere1 = sdfSphere(rayPos - _Sphere1.xyz, _Sphere1.w);
                float sphere2 = sdfSphere(rayPos - _Sphere2.xyz, _Sphere2.w);
                float box = sdfBox(rayPos - _BoxPosition, _BoxSize);
                
                // Merged shapes
                float smoothedShapes = opSmoothUnion(sphere1, sphere2, _ShapesInterpolation);
                float smoothedIntersection = opSmoothIntersection(sphere1, box, _ShapesInterpolation);
                float mergedShapes = opSmoothSubtraction(sphere1, box, _ShapesInterpolation);
                
                // Debug Shapes 
                float3 pos = rayPos - _DebugPos;
                
                
                
                float4 scaledPos = opScale(pos, _DebugParams.w);
                
                float sphere3 = sdfSphere(scaledPos.xyz, _Sphere2.w) * scaledPos.w;
                float torrus = sdfTorus(opElongate(pos, _DebugParams.xyz), 1, 0.2, _DebugAxis);
                float cappedTorrus = sdfCappedTorus(pos, _DebugParams.x, _DebugParams.y, _DebugParams.z, _DebugAxis);
                float link = sdfLink(pos, _DebugParams.x, _DebugParams.y, _DebugParams.z, _DebugAxis);
                float infCylinder = sdfInfiniteCylinder(pos, _DebugParams.x, _DebugAxis);
                float plane = sdfPlane(pos, normalize(_DebugParams.xyz), _DebugParams.w);
                float cone = sdfCone(pos, _DebugParams.x, _DebugParams.y);
                float infiniteCone = sdfInfiniteCone(pos, float2(sin(_DebugParams.x), cos(_DebugParams.x)));
                float hexPrism = sdfHexPrism(pos, _DebugParams.x, _DebugParams.y);
                float capsule = sdfCapsule(pos, float3(0,0,0), _DebugParams.xyz, _DebugParams.w);
                float capsuleAxis = sdfCapsuleAxis(pos, _DebugParams.x, _DebugParams.y, _DebugAxis);
                float cylinder = sdfCylinder(pos, float3(0,0,0), _DebugParams.xyz, _DebugParams.w);
                float cylinderAxis = sdfCylinderAxis(pos, _DebugParams.x, _DebugParams.y, _DebugAxis);
                float roundedCylinder = sdfRoundedCylinder(pos, _DebugParams.x, _DebugParams.y, _DebugParams.z, _DebugAxis);
                float cappedConeAxis = sdfCappedConeAxis(pos, _DebugParams.x, _DebugParams.y, _DebugParams.z, _DebugAxis);
                float cappedCone = sdfCappedCone(pos, float3(0,0,0), _DebugParams.xyz, 1, _DebugParams.w);
                float solidAngleA = sdfSolidAngle(pos, float2(sin(_DebugParams.x),cos(_DebugParams.x)), _DebugParams.z, _DebugAxis);
                float solidAngleB = sdfSolidAngle(pos, _DebugParams.x, _DebugParams.z, _DebugAxis);
                float cutSphere = sdfCutSphere(pos.yzx, _DebugParams.x, _DebugParams.y, _DebugAxis);
                float cutHollowSphere = sdfCutHollowSphere(pos, _DebugParams.x, _DebugParams.y, _DebugParams.z, _DebugAxis);
                float deathStar = sdfDeathStar(pos, _DebugParams.x, _DebugParams.y, _DebugParams.z, _DebugAxis);
                float roundCone = sdfRoundCone(pos, float3(0,0,0), float3(_DebugParams.x,_DebugParams.y,0), _DebugParams.z, _DebugParams.w);
                float roundConeAxis = sdfRoundConeAxis(pos, _DebugParams.x, _DebugParams.y, _DebugParams.z, _DebugAxis);
                float vesica = sdfVesicaSegment(pos, float3(0,0,0), _DebugParams.xyz, _DebugParams.w);
                float rhombus = sdfRhombus(pos, _DebugParams.x, _DebugParams.y, _DebugParams.z, _DebugParams.w);
                float octahedron = sdfOctahedron(pos, _DebugParams.x);
                float octahedronBound = sdfOctahedronBound(pos, _DebugParams.x);
                float pyramid = sdfPyramid(pos, _DebugParams.x);
                float triangleShape = sdfTriangle(pos, float3(-1,0,0), _DebugParams.xyz, float3(1,0,0));
                float quad = sdfQuad(pos, float3(-1,0,0), float3(-1,1,1), float3(1,1,1), float3(1,0,0));
                float trianglePrism = sdfTrianglePrism(pos, _DebugParams.x, _DebugParams.y);
                float ellipsoid = sdfEllipsoid(pos, _DebugParams.xyz);
                float onionSphere = max(opOnion(opOnion(sphere3, _DebugParams.x), _DebugParams.y), pos.y); // max(sdf, pos.y) to be able to see sdf interior
                
                return onionSphere;
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
