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
        

        // Dispatch: Generate thread groups to process the texture
        // -> kernel index: index of the function (id start at 0 and each new function we define with #pragma takes the next id, kernel index order is defined from top to bottom)
        // -> threadGroupsX: number of work group in X dimension (width of the texture divided by X column size of the thread group)
        // -> threadGroupsY: number of work group in Y dimension (eight of the texture divided by Y row size of the thread group)
        // -> threadGroupsZ: number of work group in Z dimension (depth of the texture divided by Z size of the thread group)
        // => the texture is split into groups of texels called thread groups that will be processed on different compute unit. To calculate the number of thread groups we divide the size
        //    of our texture by the number of threads we use for each dimension and we generate a grid of thread group on the texture
        //      -> in this example our texture size is 256*256 and we defined [numthreads(8,8,1)] in the compute shader:
        //          - threadGroupsX = 256/8 = 32
        //          - threadGroupsY = 256/8 = 32
        //          - threadGroupsZ = 1/1 = 1 (we use a 2D texture so there is no depth on Z axis).
        //        => This gives us a grid of 32x32x1 thread groups that will calculate our texture
        shader.Dispatch(0, texSize/8, texSize/8, 1);
        
        // WIP: I need to clarify this for myself
        
        // -> texture = divided into a grid of thread groups
        // -> thread group = composed of numthreads(X,Y,Z) threads, every thread inside a thread group will calculate the value of a texel
        
        // Why do we use numthreads XYZ to define number of thread groups:
        // -> Each thread group will calculate a block of numthreadX * numthreadY * numthreadZ texels, so if we want our thread groups grid to cover the whole size of our texture
        //    we need to use the right number of thread group on every axis.
        // -> For example with a texture of 256*256 if we use 8*8*1 numthreads this means every thread group calculate a block of 8 * 8 * 1 texels (64 texels in total). So the number of
        //    thread group we need to calculate the whole texture is:
        //     - X=32: 256 = X * 8 or X = 256/8 (texture width = number of Thread Group * numthread X)
        //     - Y=32: 256 = Y * 8 or Y = 256/8 (texture height = number of Thread Group * numthread Y
        //     - Z=1: 1 = Z * 1 or Z = 1/1 (texture depth = number of Thread Group * numthread Z
        // -> so for example if for the same texture size (256*256), I keep the same number of thread groups (32*32*1) but I change my numthreads to 4*4*1.
        //      -> 32 * 32 thread blocks of 4 * 4 * 1 texels = texture of 128*128 => we will only calculate a quarter of the texture
        
        // Every thread group is executed on an independant compute unit because different groups of thread cannot be synchronized, in fact we have no control on the order
        // that will be used to process the thread groups. Thread synchronization can only happen on thread within the same group.
        
        // Our grid is composed of thread groups and every thread group has a number of thread defined by [numthreads(8,8,1)] (so 8 * 8 * 1 = 64 threads in this case)
        // Every thread calculate the value of a texel.
        
        // SV_DispatchThreadID = [(SV_GroupID) * (numthreads)] + (SV_GroupThreadID)
        // -> sum of the number of threads for each group we use + index of each thread
        
        // Note: SV_GroupID = index of a group that will be executed in the compute shader
        //        |-> numthreads = total of threads for each groups
        //              |-> SV_GroupThreadId = id of each individual thread
        
        
    }


    void Update()
    {
        
    }
}
