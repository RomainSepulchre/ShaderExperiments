using UnityEngine;

public class BuffersController : MonoBehaviour
{
    public ComputeShader shader;

    [Range(0f, 0.5f)] public float radius = 0.5f;
    [Range(0f, 1f)] public float center = 0.5f;
    [Range(0f, 0.5f)] public float smooth = 0.01f;
    [Range(0f, 20f)] public float circleDist = 0.25f;
    public Color mainColor = new Color();
    
    private RenderTexture rt;
    private int rtSize = 128;
    private Renderer rend;
    
    // Compute Buffer declaration
    struct Circle
    {
        public float radius;
        public float center;
        public float smooth;
    }
    
    Circle[] circles; // array of Circle to access each variable

    private ComputeBuffer buffer;

    void Start()
    {
        CreateShaderTexture();
        
        //SetShaderTexture();
    }
    
    void Update()
    {
        SetShaderTexture();
    }
    
    void CreateShaderTexture()
    {
        // Create RenderTexture
        rt = new RenderTexture(rtSize, rtSize, 0, RenderTextureFormat.ARGB32);
        rt.enableRandomWrite = true;
        rt.Create();
        
        // Access meshRenderer
        rend = GetComponent<Renderer>();
        rend.enabled = true;
    }

    void SetShaderTexture()
    {
        uint threadGroupSizeX;
        
        // return the dimensions of numthreads 
        shader.GetKernelThreadGroupSizes(0, out threadGroupSizeX, out _, out _);

        int size = (int)threadGroupSizeX;
        
        // initialize circle array and fill it
        circles = new Circle[size];
        for (int i = 0; i < size; i++)
        {
            Circle circle = circles[i];
            circle.radius = radius;
            circle.center = center + (i / (float)size) * circleDist;
            circle.smooth = smooth;
            circles[i] = circle;
        }
        
        // Initialize compute buffer
        // Strides
        // -> number of bits require for a Circle (3 float variable = 3 * 4 bits = 12)
        // -> another easier way to get the size is: "int stride = System.Runtime.InteropServices.Marshal.SizeOf(typeof(Circle));"
        int stride = 12; // 
        buffer = new ComputeBuffer(circles.Length, stride, ComputeBufferType.Default); //  number of element in the buffer, size of the element in bits, type of buffer
        buffer.SetData(circles);
        
        // Set compute shader variables
        shader.SetBuffer(0, "CircleBuffer", buffer);
        shader.SetTexture(0, "Result", rt);
        shader.SetVector("mainColor", mainColor);
        
        // Apply RenderTexture to object material
        rend.material.SetTexture("_MainTex", rt);
        
        // Dispatch
        // -> Why size, size when numthreads(128,1,1) ???
        shader.Dispatch(0, size/128, size/1, 1);
        
        // Dispose buffer
        buffer.Release();
    }
}
