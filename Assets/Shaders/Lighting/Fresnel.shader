// Shader that shows how environmental fresnel effect works

// The fresnel effect is a type of reflection where its size is proportional to the incidence angle (the angle between
// the object normals and the camera direction). The fresnel effect create a reflection on the rim of the object.

// The more the surface is far from the camera, the more fresnel reflection we will have because the angle between the incidence
// value and the object normal increase when the surface get further from the camera.

// When the angle between the incidence value and the normal equals 0° there is no reflection because the vectors are parallel and
// when the angle is 90° the reflection will be full because the vectors are perpendicular. This is very handy because in term of
// colors we must return black when the reflections are null and white when the reflection is full.


Shader "LearnShader/Lighting/Fresnel (BIRP Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // Fresnel effect properties
        _FresnelPow ("Fresnel Power", Range(1,5)) = 1
        _FresnelInt ("Fresnel Intensity", Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL; // Get normal
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal_world : TEXCOORD1; // Pass normal to frag() in worldSpace
                float3 vertex_world : TEXCOORD2; // vertex position in world space to calculate view direction
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            // Fresnel properties connection variables
            float _FresnelPow;
            float _FresnelInt;
            
            
            // Fresnel function used in the fresnel effect shader graph node
            void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
            {
                Out = pow((1.0 - saturate(dot(normalize(Normal), ViewDir))), Power);
                // This operation can be divided into 3 parts:
                
                //  - saturate(dot(normal, viewDir)): we determine the angle between the incidence vector and the surface normal
                //      -> dot(normal,viewDir) will return a result between -1 and 1 and since we want a value between 0 and 1 we
                //         call saturate() to limit the value between a 0 to 1 range. Saturate() simply Clamp() the value between 0 and 1.
                
                //  - (1 - saturate(...)): a dot product return 1 when the vectors are parallel and 0 when they form a right-angle so we
                //    need to flip the result to have black (0) when there are parallel and white (1) when we have a right-angle.
                
                //  - pow((1 - saturate(...)), Power): the power function allows us to increase/decrease the range of reflection
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normal_world = UnityObjectToWorldNormal(v.normal); // convert the normal to world-space
                o.vertex_world = mul(unity_ObjectToWorld, v.vertex); // convert vertex position to world-space
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // Fresnel parameters
                float3 normal = i.normal_world;
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.vertex_world));
                float fresnel = 0;
                
                // Calculate fresnel reflection
                Unity_FresnelEffect_float(normal, viewDir, _FresnelPow, fresnel);
                
                // Ass fresnel reflections
                col += fresnel * _FresnelInt;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
