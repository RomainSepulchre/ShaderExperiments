using UnityEngine;

// C# script associated with SimpleColor compute shader

public class SimpleColorController : MonoBehaviour
{
    // Declare a public variable to bind and access the compute shader to the c# script
    public ComputeShader shader;
    
    // Declare a render texture variable to store the texture from the compute shader 
    public RenderTexture rt;
    
    // define a size for our texture (usually a power of 2: 128, 256, 512, 1024, ...)
    private int texSize = 256;
    
    // Define a renderer component to apply compute shader calculation on its material
    Renderer rend;

    void Start()
    {
        // Initialize our render texture with its size, depthBuffer and texture format
        rt = new RenderTexture(texSize, texSize, 0, RenderTextureFormat.ARGB32);
        
        // Enable random writing on the render texture
        // -> since thread groups are not synchronized we can't determine which texel will be calculated first so we need to enable
        //    enableRandomWrite before creating the texture
        rt.enableRandomWrite = true;
        
        // Create texture
        // -> Render Texture builder does not actually create a texture, it's only created when Create() is called
        rt.Create();
        
        // Get Renderer and enable it
        rend = GetComponent<Renderer>();
        rend.enabled = true;
        
        // The texture is created but it doesn't have any colors assigned so we must send it to the compute shader, it will assign new colors
        // from the calculations defined inside CSMain
        // -> kernel index: index of the function (id start at 0 and each new function we define with #pragma takes the next id, kernel index order is defined from top to bottom)
        // -> name: name of the buffer texture variable defined in our compute shader
        // -> texture: texture that we will write into
        shader.SetTexture(0, "Result", rt);
        
        // Apply texture to Quad material
        rend.material.SetTexture("_MainTex", rt);
        

        // Dispatch: Generate thread groups to process the texture
        // -> kernel index: index of the function (id start at 0 and each new function we define with #pragma takes the next id, kernel index order is defined from top to bottom)
        // -> threadGroupsX: number of work group in X dimension (width of the texture divided by X column size of numthreads)
        // -> threadGroupsY: number of work group in Y dimension (eight of the texture divided by Y row size of numthreads)
        // -> threadGroupsZ: number of work group in Z dimension (depth of the texture divided by Z size of numthreads)
        // => Each thread group will calculate a block of numthreadX * numthreadY * numthreadZ texels, so if we want our thread groups grid to cover the whole size of our texture
        //    we need to use the right number of thread group on every axis.
        //      - Here we want to draw 256 * 256 texels and every thread group draw 8 * 8 * 1 texel so we have:
        //          - X = 256/8 = 32 because 256 = X * 8 (texture width = threadGroupX * numthread X)
        //          - Y = 256/8 = 32 because 256 = Y * 8 (texture height = threadGroupY * numthread Y)
        //          - Z = 1/1 = 1 because 1 = Z * 1 (texture depth = threadGroupZ * numthread Z)
        shader.Dispatch(0, texSize/8, texSize/8, 1);
    }


    void Update()
    {
        
    }
}
