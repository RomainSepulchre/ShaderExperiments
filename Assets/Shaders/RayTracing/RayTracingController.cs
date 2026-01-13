using System;
using UnityEngine;
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
        Spheres = 5
    }
    [SerializeField] private Mode RenderMode = Mode.CSMain;
    public bool useAntialiasing;
    public ComputeShader shader;
    public Texture skybox;
    private uint currentSample;
    private Material antiAliasingMaterial;

    private RenderTexture rt;
    private Camera cam;

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
    }
}
