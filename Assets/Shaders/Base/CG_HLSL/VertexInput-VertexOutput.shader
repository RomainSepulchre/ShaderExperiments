// Shader with annotation CG/HLSL Vertex Input and Vertex Output

// See https://docs.unity3d.com/6000.1/Documentation/Manual/SL-VertexProgramInputs.html

Shader "LearnShader/BIRP_Unlit/CG_HLSL/VertexInput-VertexOutput"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            // Struct

            // -> Like in C,C# or C++, struct is a compound data type (a type that allows to groups multiple simpler data) and contrary to a
            //    class it is a value type (variables hold their actual data in their own memory allocation) which make its variables accessible
            //    through a single pointer.
            // -> In CG/HLSL struct are used to define Inputs and Outputs values in the shader.

            // Example of struct:
            struct name // the name of the struct
            {
                // when we declare a variable inside the struct we declare its type and name and then we associate the variable with a SEMANTIC
                // to tell the information we want to get in the variable. 
                float4 variableName : SEMANTIC;
                // See more info on semantics below
            };

            // Semantics

            // -> The Semantic is a string connected to shader input or output that tells the intended use of a parameter and access the relevant
            //    properties of an object to make it usable in our shader code.
            // -> For example, in the appdata struct the variable "float4 vertex : POSITION;" is declared, this means that the float4 vertex will
            //    automatically be filled with the value that correspond to the semantic POSITION which is the position of the vertex.
            // -> The most common semantics we use when working on shaders are:
            //      - POSITION (Position of the object vertices, it has up to 4 dimensions [XYZW] and W the fourth dimension is used to tell if the
            //        vector is a position in space or a direction)
            //      - TEXCOORD (UV coordinates fo the object vertices, it has up to 4 dimensions [XYZW])
            //      - TANGENT (Tangent of the object vertices, to create normal maps we need to have up to 4 dimensions [XYZW])
            //      - NORMAL (Normal of the object vertices, it has up to 4 dimensions [XYZW]. This semantic is generally used when we want to
            //        work with lighting within the shader)
            //      - COLOR (Vertex color of the object vertices, it has up to 4 dimensions [XYZW]. Default vertex color is usually white or gray)

            // Appdata and v2f structs

            // -> In a default shader, Unity add 2 structs:
            //      - appdata: stands for application data and correspond to the Vertex Input, it is the place where our object properties are
            //        stored.
            //      - v2f: stands for vertex to fragment and correspond to the Vertex Output, it is the place for the properties we pass from the
            //        vertex shader stage to the fragment shader stage

            // General flow

            // 1. We declare 2 structs: appdata and v2f. Inside theses structs we use semantics to declare the object properties we want to use
            //    in our shader code.
            // 2. When calling vert() the appdata struct is used as an argument to be able to work with the object properties inside the function.
            // 3. In vert() we declare a new v2f struct that we will return at the end of the function. Then, we rework the data from appdata
            //    and store them in v2f. For example, we use UnityObjectToClipPos() to transform appdata vertex position from object-space to 
            //    clip-space and we store this new position inside v2f.
            // 4. To conclude vert() we return the v2f struct we created that store the value reworked from appdata. 
            // 5. When calling frag() the v2f struct is used as an argument so we can used its variable inside the function.
            // 6. Inside frag() we can use the data from v2f to define the object color and we return a color that is used to draw the object to
            //    conclude the function. 

            // appdata = vertex input (object properties that we store)
            struct appdata
            {
                // Note: since we are in the vertex input appdata we assume that the vertices position are in object-space. In vert() we use
                // UnityObjectToClipPos() function to transform the position the Clip-Space (=screen coordinate)
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            // v2f = vertex output (properties we pass from the vertex to the fragment shader stage)
            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION; // Prefic SV_ means System value
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            // Vertex shader stage (stage where vertices are transformed from a 3D space to a 2D projection on the screen)
            v2f vert (appdata v) // appdata struct is used as an argument
            {
                // We declare a new v2f struct
                v2f o;

                // We process the data from appdata argument and store inside the newly created v2f variable.
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

                // We return the v2f variable that store the processed data at the end of the function
                return o; 
            }

            // Fragment shader stage
            fixed4 frag (v2f i) : SV_Target // v2f struct is used as an argument
            {
                // We use the data from v2f to define the color to draw ()
                fixed4 col = tex2D(_MainTex, i.uv);
                UNITY_APPLY_FOG(i.fogCoord, col);

                // We return a color used to drawn the pixel
                return col;
            }
            ENDCG
        }
    }
}
