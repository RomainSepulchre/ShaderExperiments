using UnityEngine;

// C# script associated with SimpleColor compute shader

public class SimpleColorController : MonoBehaviour
{
    // Declare a public variable to bind the compute shader to the c# script
    public ComputeShader shader; // ? name need to be m_shader ???
    
    // Declare a render texture variable to store the texture from the compute shader 
    public RenderTexture rt; // ? name need to be m_mainTex to be associated with _MainTex property ???
    
    // define a size for our texture (usually a power of 2: 125, 256, 512, 1024, ...)
    private int texSize = 256; // ? name need to be m_texSize to be associated with _MainTex dimension ???
    
    // Define a renderer component to apply compute shader calculation on its material
    Renderer rend; // ? name need to be m_rend ???

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
        
        // Generate thread group to process the texture
        // -> kernel index: index of the function (id start at 0 and each new function we define with #pragma takes the next id, kernel index order is defined from top to bottom)
        // -> threadGroupsX: width of the texture divided by X column size of the thread group
        // -> threadGroupsY: height of the texture divided by Y row size of the thread group 
        // -> threadGroupsZ: depth of the texture divided by Z size of the thread group (1/1 = 1)
        shader.Dispatch(0, texSize/8, texSize/8, 1);
    }


    void Update()
    {
        
    }
}
