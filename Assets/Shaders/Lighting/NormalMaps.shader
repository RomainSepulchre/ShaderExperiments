// Shader that shows how to apply a normal map

// -> Normal mapping is a technique that generate surface details without the need of adding more vertices. To do that we provide a texture
//    called a normal map and we use the color information of the texture pixels to change the direction of the normal and simulate light
//    bouncing on a volume.

// -> To change the direction of the normal we need to store all vertices within a space coordinate called tangent-space that is used for 
//    the objects surface lighting calculation.

// -> To change the direction of the normal we need to store all vertices within a space coordinate called *tangent-space* that is used for the
//    objects surface lighting calculation. To convert coordinate to *tangent-space* we need to use a **TBN matrix** that is formed of 3 normalized
//    vectors: *T* for **Tangent**, *B* for **Binormal** and *N* for **Normal**. Just like we use `unity_ObjectToWorld` matrix to convert
//    *object-space* coordinates to *world-space* coordinates, we use the **TBN matrix** to convert *world-space* coordinates to *tangent-space*.

// -> Graphical representation of TBN matrix :
//      float4x4 TBN = float4x4
//      (
//          Tx, Ty, Tz, 0, // Tangent values
//          Bx, By, Bz, 0, // BiNormal values
//          Nx, Ny, Nz, 0, // Normal values
//          0,  0,  0,  0,
//      );

// -> See https://docs.unity3d.com/6000.3/Documentation/Manual/StandardShaderMaterialParameterNormalMap.html
// -> See https://medium.com/@onlyashley04/writing-a-basic-shader-in-unity-aa7396514daa

// -> In this shader we add a normal map texture and apply it on the object:
//      - Add normal map texture property and connections variables
//      - If we want top be able to declare a TBN matrix we must get the normal and tangent in vertex input (appdata). To do that we bind a float3
//        to NORMAL semantic and float4 to TANGENT semantic
//      - Declare in the vertex output shader the value we want to pass from vert() to frag(): uv_normal, normal_world, tangent_world, binormal_world.
//      - Process Tangent and Normal in vert() to calculate the binormal, get their world-space coordinates and pass the result to the fragment shader.
//      - Unpack normal: decode compressed texture and remap RGBA value
//      - Build TBN matrix and multiply normal value by TBN matrix

Shader "LearnShader/Lighting/Normal Maps (BIRP Unlit)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        // Normal map texture property
        _NormalMap ("Normal Map", 2D) = "white" {}
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                
                // To be able to build a TBN Matrix, we get the normal and tangent in vertex input
                float3 normal : NORMAL; // we bind a float3 to NORMAL semantic
                float4 tangent : TANGENT; // we bind a float4 to TANGENT semantic
                
                // ! normal and tangent are both in object-space, we will need to convert them to world-space before converting them to tangent-space
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                
                // We need to declare in the vertex ouput the values we want to pass from vert() to frag()
                // -> No NORMAL or TANGENT semantic in v2f so we use TEXCOORD[n] instead
                float2 uv_normal : TEXCOORD1; // uv coordinate of the normal map texture
                float3 normal_world : TEXCOORD2; // normal coordinate in world-space
                float4 tangent_world : TEXCOORD3; // tangent coordinate in world-space
                float3 binormal_world : TEXCOORD4; // binormal coordinate in world-space
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            // Add connection variables for normal map property
            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            
            // DXT Decompression (this a custom equivalent of UnpackNormal() from UnityCG.cginc)
            float3 DXTDecompression (float4 normalMap)
            {
            #if defined (UNITY_NO_DXT5nm)
                // No compression, DTX5nm not supported
                // -> Not compressed, we return the normal RGB value after they have been remapped to [-1 to 1] (normalMap.rgb * 2 - 1)
                return normalMap.rgb * 2 - 1;
            #else
                // DTX Decompression
                // -> We need to decode compression
                float3 normalCol;
                // Move X and Y values: R channel is replaced by A channel, G channel stay the same
                normalCol = float3 (normalMap.a * 2 - 1, normalMap.g * 2 - 1, 0); // RGB value remap is done on alpha and green channel during decompression
                normalCol.b = sqrt( 1 - (pow(normalCol.r, 2) + pow(normalCol.g, 2)) ); // Recalculate Z value using the X and Y coordinates that have been moved in the R and G channels
                return normalCol;
            #endif
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                
                // Tilling and offset of the normal map texture
                o.uv_normal = TRANSFORM_TEX(v.uv, _NormalMap);
                
                // Transform normal and tangent to world-space
                o.normal_world = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0)));
                o.tangent_world = normalize(mul(unity_ObjectToWorld, v.tangent));
                
                // Use a cross product to calculate binormal world-space coordinates using the normal and tangent world-space coordinates
                // -> multiply cross product result by v.tangent.w to ensure the binormal has a correct orientation
                o.binormal_world = normalize(cross(o.normal_world,o.tangent_world) * v.tangent.w);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample normal map texture
                fixed4 normalMap = tex2D(_NormalMap, i.uv_normal);
                
                // We unpack the normal to compress the texture and remap RGBA value
                fixed3 normalUnpacked = UnpackNormal(normalMap); 
                //fixed3 normalDecompressed = DXTDecompression(normalMap); // DXTCompression() is a custom equivalent of UnpackNormal() from unityCG.cginc
                
                // Remap RGBA value
                // -> X,Y,Z,W coordinates of the normal map are embedded in RGBA channels that range from 0.0 to 1.0. Since a normal use value
                //    from -1 to 1f we need to remap the numerical range from [0 to 1] to [-1 to 1].
                // -> Remap calculation: normalMap.rgb = normalMap.rgb * 2 - 1;
                //      - normalMap.rgb * 2 => [0*2 to 1*2] => [0 to 2]
                //      - normalMap.rgb - 1 => [0-1 to 2-1] => [-1 to 1]
                // -> The remap is directly included in the DTX compression that UnpackNormal() does, so no need to reamp manually is the normal has been unpacked
                
                
                // Create TBN matrix
                float3x3 TBN = float3x3
                (
                    i.tangent_world.xyz,
                    i.binormal_world,
                    i.normal_world
                );
                
                // Sample main texture
                fixed4 tex = tex2D(_MainTex, i.uv);
                
                // Convert normal map to tangent-space
                normalMap = fixed4 (normalize(mul(TBN, normalUnpacked )), 1);
                
                // Mix texture and normal map            
                fixed4 col = tex * normalMap;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
