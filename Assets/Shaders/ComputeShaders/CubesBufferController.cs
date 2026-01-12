using System.Collections.Generic;
using UnityEngine;

public class CubesBufferController : MonoBehaviour
{
    [Header("Compute Shader")]
    public ComputeShader shader;
    
    [Header("Cubes parameters")]
    public GameObject cubePrefab;
    public int xDimension = 100;
    public int yDimension = 100;
    public Vector3 size = new Vector3(0.2f, 0.2f, 0.2f);
    public float maxZOffset = 0.01f;

    [Header("Randomize parameters")]
    public int repetitions = 50;
    
    private List<GameObject> cubes = new List<GameObject>();
    private List<MeshRenderer> cubesRenderers = new List<MeshRenderer>();
    
    // Compute buffer
    private struct Cube
    {
        public Vector3 localPosition;
        public Color color;
    }
    private Cube[] cubesData;
    private ComputeBuffer cubesBuffer;
    
    
    void Start()
    {
        SpawnCubes();
    }

    public void OnRandomize()
    {
        for (int i = 0; i < repetitions; i++)
        {
            for (int j = 0; j < cubes.Count; j++)
            {
                GameObject cube = cubes[j];
                cube.transform.localPosition = new Vector3(cube.transform.localPosition.x, cube.transform.localPosition.y, Random.Range(-maxZOffset, maxZOffset));
                cubesRenderers[j].material.SetColor("_Color", Random.ColorHSV());
            }
        }
    }

    public void OnRandomizeGPU()
    {
        int posSize = sizeof(float) * 3;
        int colSize = sizeof(float) * 4;
        cubesBuffer = new ComputeBuffer(cubesData.Length, posSize + colSize);
        
        cubesBuffer.SetData(cubesData);
        
        shader.SetBuffer(0, "cubes", cubesBuffer);
        shader.SetFloat("resolution", cubesData.Length);
        shader.SetFloat("repetitions", repetitions);
        shader.SetFloat("maxZOffset", maxZOffset);
        
        shader.Dispatch(0, cubesData.Length / 64, 1, 1);
        
        // Read Data processed by compute shader
        cubesBuffer.GetData(cubesData);
        
        for (int i = 0; i < cubes.Count; i++)
        {
            GameObject cube = cubes[i];
            Cube cubeData = cubesData[i];
            cube.transform.localPosition = cubeData.localPosition;
            cubesRenderers[i].material.SetColor("_Color", cubeData.color);
        }
        
        cubesBuffer.Release();
    }

    void SpawnCubes()
    {
        cubesData = new Cube[xDimension * yDimension];
        
        for (int y = 0; y < yDimension; y++)
        {
            for (int x = 0; x < xDimension; x++)
            {
                float xOffset = ((xDimension * size.x) / 2);
                float xPos = (size.x / 2) + (x * size.x) - xOffset;
                float yPos = (size.y / 2) + (y * size.y);
                float zPos = Random.Range(-maxZOffset, maxZOffset);
                
                Vector3 position = new Vector3(xPos ,yPos , zPos);
                
                GameObject cube = Instantiate(cubePrefab, this.gameObject.transform);
                
                cube.transform.position += position;
                cube.transform.localScale = size;
                MeshRenderer cubeRenderer = cube.GetComponent<MeshRenderer>();
                Color color = Random.ColorHSV();
                cubeRenderer.material.SetColor("_Color", color);

                cube.GetComponent<MeshRenderer>().material.GetColor("_Color");
                
                cubes.Add(cube);
                cubesRenderers.Add(cubeRenderer);
                
                Cube cubeData = new Cube();
                cubeData.localPosition = cube.transform.localPosition;
                cubeData.color = color;
                cubesData[x * xDimension + y] = cubeData;
                
            }
        }
    }
}
