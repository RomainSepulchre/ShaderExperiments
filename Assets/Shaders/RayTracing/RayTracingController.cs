using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;
using Random = UnityEngine.Random;

public class RayTracingController : MonoBehaviour
{
    private enum Mode
    {
        CSMain = 0,
        ColorfulSky = 1,
        Skybox = 2,
        GroundPlane = 3,
        GroundAndSpheres = 4,
        Spheres = 5,
        Reflections = 6,
        DiffuseReflections = 7
    }
    [SerializeField] private Mode RenderMode = Mode.CSMain;
    public bool useAntialiasing;
    public ComputeShader shader;
    public Texture skybox;
    public Light directionalLight;
    [Range(0, 8)] public int reflectionBounces = 8;
    public Color albedoColor = new Color(0.8f, 0.8f, 0.8f);
    [Range(0, 1)] public float specularValue = 0.6f;
    public List<Transform> spheresTransforms = new List<Transform>();
    
    // Antialiasing
    private uint currentSample;
    private Material antiAliasingMaterial;
    
    // Render Texture and Camera
    private RenderTexture rt;
    private Camera cam;
    
    // Sphere compute buffer
    struct SphereData
    {
        public Vector3 position;
        public float scale;
    }
    SphereData[] spheresDatas;
    ComputeBuffer spheresBuffer;

    private void Awake()
    {
        cam = GetComponent<Camera>();
    }

    private void Update()
    {
        if (transform.hasChanged)
        {
            currentSample = 0;
            transform.hasChanged = false;
        }
        
        if (directionalLight.transform.hasChanged)
        {
            currentSample = 0;
            directionalLight.transform.hasChanged = false;
        }
    }

    private void OnDestroy()
    {
        // TODO: ??? Why memory leaks ?
        // Ensure buffer is released at on destroy
        spheresBuffer?.Dispose(); 
    }

    // Called when camera has finished to render
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        SetShaderParameters();
        
        Render(destination);
    }

    private void Render(RenderTexture destination)
    {
        InitializeRenderTexture();

        shader.SetTexture((int)RenderMode, "Result", rt);
        SetShaderParameters();

        int threadGroupsX = Mathf.CeilToInt(Screen.width / 8.0f); // 8 -> numthreads.x
        int threadGroupsY = Mathf.CeilToInt(Screen.height / 8.0f); // 8 -> numthreads.y

        shader.Dispatch((int)RenderMode, threadGroupsX, threadGroupsY, 1);
        
        // TODO: ??? Why memory leaks ?
        spheresBuffer.Dispose(); // Release sphere buffer
        
        if (useAntialiasing)
        {
            if(antiAliasingMaterial == null) antiAliasingMaterial = new Material(Shader.Find("Hidden/Antialiasing"));
            antiAliasingMaterial.SetFloat("_Sample", currentSample);
        
            Graphics.Blit(rt, destination, antiAliasingMaterial); // Write result to screen
            currentSample++;
        }
        else
        {
            Graphics.Blit(rt, destination); // Write result to screen
        }
        
        
    }

    private void InitializeRenderTexture()
    {
        if (rt == null || rt.width != Screen.width || rt.height != Screen.height)
        {
            if (rt != null) rt.Release(); // Release already existing render texture

            rt = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat,
                RenderTextureReadWrite.Linear);
            rt.enableRandomWrite = true;
            rt.Create();
        }
    }
    
    private void SetShaderParameters()
    {
        shader.SetTexture((int)RenderMode, "SkyboxTexture", skybox);
        shader.SetMatrix("CameraToWorld", cam.cameraToWorldMatrix);
        shader.SetMatrix("CameraInverseProjection", cam.projectionMatrix.inverse);
        shader.SetVector("PixelOffset", new Vector2(Random.value, Random.value));
        shader.SetBool("UseAntialiasing", useAntialiasing);
        shader.SetInt("Bounces", reflectionBounces);
        
        Vector3 lightDir = directionalLight.transform.forward;
        shader.SetVector("DirectionalLight", new Vector4(lightDir.x, lightDir.y, lightDir.z, directionalLight.intensity));
        shader.SetVector("Albedo", albedoColor);
        shader.SetVector("Specular", new Vector3(specularValue, specularValue, specularValue));
        
        SetSpheresComputeBuffer();
    }

    private void SetSpheresComputeBuffer()
    {
        // Fill sphere array
        spheresDatas = new SphereData[spheresTransforms.Count];
        for (int i = 0; i < spheresTransforms.Count; i++)
        {
            SphereData sphereData = new SphereData();
            sphereData.position = spheresTransforms[i].position;
            sphereData.scale = spheresTransforms[i].localScale.x;
            spheresDatas[i] = sphereData;
        }
        
        // Set compute buffer
        int stride = (sizeof(float) * 3) + sizeof(float); // vector3 + float
        spheresBuffer = new ComputeBuffer(spheresDatas.Length, stride);
        spheresBuffer.SetData(spheresDatas);
        
        shader.SetBuffer((int)RenderMode, "Spheres", spheresBuffer);
    }
    
}
