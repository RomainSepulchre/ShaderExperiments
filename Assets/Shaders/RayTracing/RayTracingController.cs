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
    public Color groundColor = new Color(0.8f, 0.8f, 0.8f);
    [Range(0, 1)] public float defaultSpecular = 0.6f;
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
        public Vector3 albedo;
        public Vector3 specular;
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
        
        UpdateSpheresComputeBuffer();
    }

    private void OnEnable()
    {
        currentSample = 0;
        SetSpheresComputeBuffer();
    }

    private void OnDisable()
    {
        if(spheresBuffer != null) spheresBuffer.Release();
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
        
        // TODO: Why releasing the buffer here brings memory leaks (probably related to the call frequency of OnRenderImage())
        //if(spheresBuffer != null) spheresBuffer.Release();
        
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
        shader.SetVector("DefaultSpecular", new Vector3(defaultSpecular, defaultSpecular, defaultSpecular));
        shader.SetVector("GroundColor", new Vector3(groundColor.r, groundColor.g, groundColor.b));
        
        Vector3 lightDir = directionalLight.transform.forward;
        shader.SetVector("DirectionalLight", new Vector4(lightDir.x, lightDir.y, lightDir.z, directionalLight.intensity));
        
        //SetSpheresComputeBuffer();
        shader.SetBuffer((int)RenderMode, "Spheres", spheresBuffer);
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
            // sphereData.albedo = new Vector3(albedoColor.r, albedoColor.g, albedoColor.b);
            // sphereData.specular = new Vector3(specularValue, specularValue, specularValue);
            Color color = Random.ColorHSV();
            bool metal = Random.value < 0.5f;
            sphereData.albedo = metal ? Vector3.zero : new Vector3(color.r, color.g, color.b);
            sphereData.specular = metal ? new Vector3(color.r, color.g, color.b) :  Vector3.one * defaultSpecular;
            spheresDatas[i] = sphereData;
        }
        
        // Set compute buffer
        int stride = (3 * (sizeof(float) * 3)) + sizeof(float); // 3 * vector3 + float
        spheresBuffer = new ComputeBuffer(spheresDatas.Length, stride);
        spheresBuffer.SetData(spheresDatas);
    }
    
    private void UpdateSpheresComputeBuffer()
    {
        if(spheresDatas.Length == 0) return;
        
        for (int i = 0; i < spheresDatas.Length; i++)
        {
            spheresDatas[i].position = spheresTransforms[i].position;
            spheresDatas[i].scale = spheresTransforms[i].localScale.x;
        }
        
        // Release previous buffer before assigning new buffer
        if(spheresBuffer != null) spheresBuffer.Release();
        
        // Set compute buffer
        int stride = (3 * (sizeof(float) * 3)) + sizeof(float); // 3 * vector3 + float
        spheresBuffer = new ComputeBuffer(spheresDatas.Length, stride);
        spheresBuffer.SetData(spheresDatas);
    }
    
}
