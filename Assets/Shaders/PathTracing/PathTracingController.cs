using System;
using System.Collections.Generic;
using System.Linq;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.Serialization;
using Random = UnityEngine.Random;

public class PathTracingController : MonoBehaviour
{
    [Header("Resources")]
    public ComputeShader shader;
    public Texture skybox;
    public Light directionalLight;
    
    [Header("General settings")]
    public int randomSeed;
    
    private enum Mode
    {
        CSMain = 0,
        OnlyRayTracing = 1,
        Lambert = 2,
        Phong = 3,
        BetterSampling = 4,
        ImportanceSampling = 5,
        SmoothnessEmission = 6
    }
    [Header("Rendering")]
    [SerializeField] private Mode RenderMode = Mode.CSMain;
    [UnityEngine.Range(0, 8)] public int reflectionBounces = 8;
    [UnityEngine.Range(0, 1)] public float defaultSpecular = 0.6f;
    public float phongAlpha = 15f;
    
    [Header("Ground")]
    public bool renderGround = true;
    public Color groundColor = new Color(0.8f, 0.8f, 0.8f);
    
    [Header("Spheres")]
    public bool renderSpheres = true;
    public List<Transform> spheresTransforms = new List<Transform>();
    
    [Space(10)]
    public bool useRandomSpheres;
    public int randomSpheresMaxCount = 100;
    public Vector2 randomSpheresMinMaxScale = new Vector2(3.0f, 8.0f);
    public float randomSpheresPlacementRadius = 100f;

    [Header("Triangle")]
    public bool renderTriangle = true;
    public Transform[] triangleVertices = new Transform[3];
    
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
        public float smoothness;
        public Vector3 emission;
    }
    SphereData[] spheresDatas;
    ComputeBuffer spheresBuffer;
    
    // Ray-traced object
    private static bool meshObjectsNeedRebuilding = false;
    private static List<PathTracedObject> rayTracedObjects = new List<PathTracedObject>();

    struct MeshObject
    {
        public Matrix4x4 localToWorldMatrix;
        public int indicesOffset;
        public int indicesCount;
        public Vector3 albedo;
        public float specular;
        public float smoothness;
        public Vector3 emission;
    }
    
    private static List<MeshObject> meshObjects = new List<MeshObject>();
    private static List<Vector3> vertices = new List<Vector3>();
    private static List<int> indices = new List<int>();
    private ComputeBuffer meshObjectBuffer;
    private ComputeBuffer vertexBuffer;
    private ComputeBuffer indexBuffer;

    private bool UseSmoothnessAndEmission => RenderMode == Mode.CSMain || RenderMode == Mode.SmoothnessEmission;

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

        foreach (Transform tf in spheresTransforms)
        {
            if (tf.hasChanged)
            {
                currentSample = 0;
                tf.hasChanged = false;
            }
        }

        foreach (Transform tf in triangleVertices)
        {
            if (tf.hasChanged)
            {
                currentSample = 0;
                tf.hasChanged = false;
            }
        }
        
        UpdateSpheresComputeBuffer();
        
        // Draw triangle line
        Debug.DrawLine(triangleVertices[0].position, triangleVertices[1].position);
        Debug.DrawLine(triangleVertices[1].position, triangleVertices[2].position);
        Debug.DrawLine(triangleVertices[2].position, triangleVertices[0].position);
    }

    private void OnEnable()
    {
        currentSample = 0;
        SetSpheresComputeBuffer();
    }

    private void OnDisable()
    {
        if(spheresBuffer != null) spheresBuffer.Release();
        if(meshObjectBuffer != null) meshObjectBuffer.Release();
        if (vertexBuffer != null) vertexBuffer.Release();
        if (indexBuffer != null) indexBuffer.Release();
    }

    // Called when camera has finished to render
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        RebuildMeshObjectBuffers();
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
        
        if(antiAliasingMaterial == null) antiAliasingMaterial = new Material(Shader.Find("Hidden/Antialiasing"));
        antiAliasingMaterial.SetFloat("_Sample", currentSample);
        
        Graphics.Blit(rt, rtConverged, antiAliasingMaterial);
        Graphics.Blit(rtConverged, destination); // Write result to screen
        currentSample++;
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
        shader.SetInt("Bounces", reflectionBounces);
        shader.SetVector("DefaultSpecular", new Vector3(defaultSpecular, defaultSpecular, defaultSpecular));
        shader.SetVector("GroundColor", new Vector3(groundColor.r, groundColor.g, groundColor.b));
        shader.SetFloat("Seed", Random.value); // This little fucker make me lose a full afternoon, value must be 0.1 so we use Random.value, I was using randomSeed by mistake   
        shader.SetFloat("Alpha", phongAlpha);
        shader.SetBool("TraceGround", renderGround);
        shader.SetBool("TraceSpheres", renderSpheres);
        shader.SetBool("TraceTriangles", renderTriangle);
        
        // Triangle vertex
        shader.SetVector("TriangleVertex1", triangleVertices[0].position);
        shader.SetVector("TriangleVertex2", triangleVertices[1].position);
        shader.SetVector("TriangleVertex3", triangleVertices[2].position);
        
        Vector3 lightDir = directionalLight.transform.forward;
        shader.SetVector("DirectionalLight", new Vector4(lightDir.x, lightDir.y, lightDir.z, directionalLight.intensity));
        
        //SetSpheresComputeBuffer();
        SetComputeBuffer("Spheres", spheresBuffer);
        
        // Mesh object buffers
        SetComputeBuffer("Meshes", meshObjectBuffer);
        SetComputeBuffer("Vertices", vertexBuffer);
        SetComputeBuffer("Indices", indexBuffer);
    }


    private void SetSpheresComputeBuffer()
    {
        // Init random seed (to keep same random value every play as long as we keep same seed)
        Random.InitState(randomSeed);

        if (useRandomSpheres) // Use a random sphere placement
        {
            SpawnRandomSpheres();
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
                Color color = Random.ColorHSV();
                bool metal = RenderMode == Mode.Lambert ? false : Random.value < 0.5f;
                sphereData.albedo = metal ? Vector3.zero : new Vector3(color.r, color.g, color.b);
                sphereData.specular = metal ? new Vector3(color.r, color.g, color.b) :  Vector3.one * defaultSpecular;
                sphereData.smoothness = Random.value;
                
                // Set ~20% of emissive sphere
                float chanceOfEmissive = Random.value;
                if (UseSmoothnessAndEmission && chanceOfEmissive > 0.8f)
                {
                    // Reset albedo, specular and smoothness
                    sphereData.albedo = Vector3.zero;
                    sphereData.specular = Vector3.zero;
                    sphereData.smoothness = 0.0f;
                        
                    // Set emissive
                    Color emission = Random.ColorHSV(0, 1, 0, 1, 3.0f, 8.0f);
                    sphereData.emission = new Vector3(emission.r, emission.g, emission.b);
                }
                
                spheresDatas[i] = sphereData;
            }
        }
        
        // Set compute buffer
        int stride = (4 * (sizeof(float) * 3)) +  (2 * sizeof(float)); // 4 * vector3 + 2 * float
        spheresBuffer = new ComputeBuffer(spheresDatas.Length, stride);
        spheresBuffer.SetData(spheresDatas);
    }
    
    private void UpdateSpheresComputeBuffer()
    {
        if(spheresDatas.Length == 0) return;
        
        if(spheresDatas.Length != spheresTransforms.Count) Debug.LogError($"Difference between spheresTransforms.Count ({spheresTransforms.Count}) and sphereDatas.Length ({spheresDatas.Length}): this may lead to issue when updating the spheres");
        
        for (int i = 0; i < spheresDatas.Length; i++)
        {
            spheresDatas[i].position = spheresTransforms[i].position;
            spheresDatas[i].scale = spheresTransforms[i].localScale.x;
        }
        
        // Release previous buffer before assigning new buffer
        if(spheresBuffer != null) spheresBuffer.Release();
        
        // Set compute buffer
        int stride = (4 * (sizeof(float) * 3)) +  (2 * sizeof(float)); // 4 * vector3 + 2 * float
        spheresBuffer = new ComputeBuffer(spheresDatas.Length, stride);
        spheresBuffer.SetData(spheresDatas);
    }

    private void SpawnRandomSpheres()
    {
        List<SphereData> spheresAdded = new List<SphereData>();
        spheresTransforms = new List<Transform>();
        GameObject spheresParent = new GameObject("Random spheres");

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
            
            GameObject spheresObj = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            spheresObj.name = $"Sphere_{i}";
            spheresObj.transform.parent = spheresParent.transform;
            spheresObj.transform.position = sphere.position;
            spheresObj.transform.localScale = Vector3.one * sphere.scale;
            
            // Albedo and specular color
            Color color = Random.ColorHSV();
            bool metal = RenderMode == Mode.Lambert ? false : Random.value < 0.5f;
            sphere.albedo = metal ? Vector3.zero : new Vector3(color.r, color.g, color.b);
            sphere.specular = metal ? new Vector3(color.r, color.g, color.b) : Vector3.one * 0.04f;
            sphere.smoothness = Random.value;
            
            // Set ~20% of emissive sphere
            float chanceOfEmissive = Random.value;
            if (UseSmoothnessAndEmission && chanceOfEmissive > 0.8f)
            {
                // Reset albedo, specular and smoothness
                sphere.albedo = Vector3.zero;
                sphere.specular = Vector3.zero;
                sphere.smoothness = 0.0f;
                    
                // Set emissive
                Color emission = Random.ColorHSV(0, 1, 0, 1, 3.0f, 8.0f);
                sphere.emission = new Vector3(emission.r, emission.g, emission.b);
            }
            
            // Add the sphere to the list
            spheresAdded.Add(sphere);
            spheresTransforms.Add(spheresObj.transform);

            SkipSphere:
            continue;
        }
        
        spheresDatas = spheresAdded.ToArray();
    }

    public static void RegisterObject(PathTracedObject obj)
    {
        rayTracedObjects.Add(obj);
        meshObjectsNeedRebuilding = true;
    }

    public static void UnregisterObject(PathTracedObject obj)
    {
        rayTracedObjects.Remove(obj);
        meshObjectsNeedRebuilding = true;
    }

    private void RebuildMeshObjectBuffers()
    {
        if (!meshObjectsNeedRebuilding)
        {
            return;
        }
        
        meshObjectsNeedRebuilding = false;
        currentSample = 0;
        
        meshObjects.Clear();
        vertices.Clear();
        indices.Clear();

        foreach (PathTracedObject obj in rayTracedObjects)
        {
            
            Mesh mesh = obj.GetComponent<MeshFilter>().sharedMesh;
            
            int firstVertex = vertices.Count;
            vertices.AddRange(mesh.vertices);
            
            int firstIndex = indices.Count;
            int[] objIndices = mesh.GetIndices(0);
            indices.AddRange(objIndices.Select(index => index + firstVertex));
            
            meshObjects.Add(new MeshObject()
            {
                localToWorldMatrix =  obj.transform.localToWorldMatrix,
                indicesOffset = firstIndex,
                indicesCount =  objIndices.Length,
                albedo = new Vector3(obj.albedo.r, obj.albedo.g, obj.albedo.b),
                specular = obj.specular,
                smoothness = obj.smoothness,
                emission = new Vector3(obj.emission.r, obj.emission.g, obj.emission.b)
            });
            Debug.Log($"Build mesh object: {obj.name} - indicesOffset = {firstIndex}, indicesCount = {objIndices.Length}");
            Debug.Log($"Vertices: count = {mesh.vertices.Length} --> {mesh.vertices.MergeAsString()}");
            Debug.Log($"Indices: count = {objIndices.Select(index => index + firstIndex).ToArray().Length} --> {objIndices.Select(index => index + firstIndex).ToList().MergeAsString()}");
        }

        int meshObjStride = 104; // Matrix4x4 = 4 * 4 * sizeof(float) + int = sizeof(int) + int = sizeof(int) + 2 * Vector3 = 2 * 3 * sizeof(float) + 2 float = 2 * sizeof(float)
        CreateComputeBuffer(ref meshObjectBuffer, meshObjects, meshObjStride);
        int vertStride = 12; // Vector3 = 3 * sizeof(float)
        CreateComputeBuffer(ref vertexBuffer, vertices, vertStride);
        int indexStride = 4; // int = sizeof(int)
        CreateComputeBuffer(ref indexBuffer, indices, indexStride);
    }

    private static void CreateComputeBuffer<T>(ref ComputeBuffer buffer, List<T> data, int stride) where T : struct
    {
        if (buffer != null)
        {
            if (data.Count == 0 || buffer.count != data.Count || buffer.stride != stride)
            {
                buffer.Release();
                buffer = null;
            }
        }

        if (data.Count != 0)
        {
            if (buffer == null)
            {
                buffer = new ComputeBuffer(data.Count, stride);
            }
            
            buffer.SetData(data);
        }
    }

    private void SetComputeBuffer(string name, ComputeBuffer buffer)
    {
        if(buffer != null) shader.SetBuffer((int)RenderMode, name, buffer);
    }
}
