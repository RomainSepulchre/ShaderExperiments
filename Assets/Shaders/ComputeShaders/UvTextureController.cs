using UnityEngine;

public class UvTextureController : MonoBehaviour
{
    public ComputeShader shader; // Compute shader
    public Texture texture; // the texture to process inside the compute shader
    
    private RenderTexture rt; // Output texture from the compute shader
    private int rtSize = 256; // width and height of the render texture
    private Renderer rend; // renderer to access and update object material
    
    void Start()
    {
        // Create Render Texture with random write enable for compute shader output
        rt = new RenderTexture(rtSize, rtSize, 0, RenderTextureFormat.ARGB32);
        rt.enableRandomWrite = true;
        rt.Create();
        
        // Get Renderer
        rend = GetComponent<Renderer>();
        rend.enabled = true;
        
        // Set compute shader variables
        shader.SetTexture(0, "Result", rt); // Set compute shader Result output texture
        shader.SetTexture(0, "texColor", texture); // Set texture to sample in the compute shader
        shader.SetBool("repeatTexture", texture.wrapMode == TextureWrapMode.Repeat); // Set bool to tell when repeat wrap mode is used
        
        // Apply RenderTexture to object material
        rend.material.SetTexture("_MainTex", rt);
        
        // Dispatch compute shader
        shader.Dispatch(0, rtSize/8, rtSize/8, 1);
    }
}
