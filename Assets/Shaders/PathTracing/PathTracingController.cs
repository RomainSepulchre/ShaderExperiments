using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;
using Random = UnityEngine.Random;

public class PathTracingController : MonoBehaviour
{
    [Header("General settings")]
    public int randomSeed;
    private enum Mode
    {
        CSMain = 0,
        OnlyRayTracing = 1,
        Lambert = 2,
        Phong = 3,
        BetterSampling = 4
    }
    [SerializeField] private Mode RenderMode = Mode.CSMain;
    public bool useAntialiasing;
    public ComputeShader shader;
    public Texture skybox;
    public Light directionalLight;
    [Range(0, 8)] public int reflectionBounces = 8;
    public Color groundColor = new Color(0.8f, 0.8f, 0.8f);
    [Range(0, 1)] public float defaultSpecular = 0.6f;
    public float phongAlpha = 15f;
    
    [Header("Random spheres placement settings")]
    public bool useRandomSpheres;
    public int randomSpheresMaxCount = 100;
    public Vector2 randomSpheresMinMaxScale = new Vector2(3.0f, 8.0f);
    public float randomSpheresPlacementRadius = 100f;
    
    [Header("Spheres linked to transform settings")]
    public List<Transform> spheresTransforms = new List<Transform>();
    
    // Antialiasing
    private uint currentSample;
    private Material antiAliasingMaterial;
    
    // Render Texture and Camera
    private RenderTexture rt;
    private RenderTexture rtConverged;
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
    
        int threadGroupsX = Mathf.CeilToInt(Screen.width / 8.0f); // 8 -> numthreads.x
        int threadGroupsY = Mathf.CeilToInt(Screen.height / 8.0f); // 8 -> numthreads.y
    
        shader.Dispatch((int)RenderMode, threadGroupsX, threadGroupsY, 1);
        
        // TODO: Why releasing the buffer here brings memory leaks (probably related to the call frequency of OnRenderImage())
        //if(spheresBuffer != null) spheresBuffer.Release();
        
        if (useAntialiasing)
        {
            if(antiAliasingMaterial == null) antiAliasingMaterial = new Material(Shader.Find("Hidden/Antialiasing"));
            antiAliasingMaterial.SetFloat("_Sample", currentSample);
            
            Graphics.Blit(rt, rtConverged, antiAliasingMaterial);
            Graphics.Blit(rtConverged, destination); // Write result to screen
            currentSample++;
        }
        else
        {
            Graphics.Blit(rt, rtConverged);
            Graphics.Blit(rtConverged, destination); // Write result to screen
        }
    }

    private void InitializeRenderTexture()
    {
        if (rt == null || rt.width != Screen.width || rt.height != Screen.height)
        {
            if (rt != null)
            {
                rt.Release(); // Release already existing render texture
                rtConverged.Release();
            }
    
            rt = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            rt.enableRandomWrite = true;
            rt.Create();
            rtConverged = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            rtConverged.enableRandomWrite = true;
            rtConverged.Create();
    
            currentSample = 0;
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
        shader.SetFloat("Seed", Random.value); // This little fucker make me lose a full afternoon, value must be 0.1 so we use Random.value, I was using randomSeed by mistake   
        shader.SetFloat("Alpha", phongAlpha);
        
        Vector3 lightDir = directionalLight.transform.forward;
        shader.SetVector("DirectionalLight", new Vector4(lightDir.x, lightDir.y, lightDir.z, directionalLight.intensity));
        
        //SetSpheresComputeBuffer();
        shader.SetBuffer((int)RenderMode, "Spheres", spheresBuffer);
    }


    private void SetSpheresComputeBuffer()
    {
        // Init random seed
        Random.InitState(randomSeed);

        if (useRandomSpheres) // Use a random sphere placement
        {
            List<SphereData> spheresAdded = new List<SphereData>();

            // Add a number of random spheres
            for (int i = 0; i < randomSpheresMaxCount; i++)
            {
                SphereData sphere = new SphereData();

                // Radius and radius
                sphere.scale = randomSpheresMinMaxScale.x + Random.value * (randomSpheresMinMaxScale.y - randomSpheresMinMaxScale.x);
                float sphereRadius = sphere.scale / 2;
                Vector2 randomPos = Random.insideUnitCircle * randomSpheresPlacementRadius;
                sphere.position = new Vector3(randomPos.x, sphereRadius, randomPos.y);

                // Reject spheres that are intersecting others
                foreach (SphereData other in spheresAdded)
                {
                    float otherRadius = other.scale / 2;
                    float minDist = sphereRadius + otherRadius;
                    if (Vector3.SqrMagnitude(sphere.position - other.position) < minDist * minDist)
                        goto SkipSphere;
                }

                // Albedo and specular color
                Color color = Random.ColorHSV();
                bool metal = RenderMode == Mode.Lambert ? false : Random.value < 0.5f;
                sphere.albedo = metal ? Vector3.zero : new Vector3(color.r, color.g, color.b);
                sphere.specular = metal ? new Vector3(color.r, color.g, color.b) : Vector3.one * 0.04f;

                // Add the sphere to the list
                spheresAdded.Add(sphere);

                SkipSphere:
                continue;
            }
            
            spheresDatas = spheresAdded.ToArray();
        }
        else // Use array of transform to place spheres
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
                bool metal = RenderMode == Mode.Lambert ? false : Random.value < 0.5f;
                sphereData.albedo = metal ? Vector3.zero : new Vector3(color.r, color.g, color.b);
                sphereData.specular = metal ? new Vector3(color.r, color.g, color.b) :  Vector3.one * defaultSpecular;
                spheresDatas[i] = sphereData;
            }
        }
        
        // Set compute buffer
        int stride = (3 * (sizeof(float) * 3)) + sizeof(float); // 3 * vector3 + float
        spheresBuffer = new ComputeBuffer(spheresDatas.Length, stride);
        spheresBuffer.SetData(spheresDatas);
    }
    
    private void UpdateSpheresComputeBuffer()
    {
        if(spheresDatas.Length == 0 || useRandomSpheres) return;
        
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
