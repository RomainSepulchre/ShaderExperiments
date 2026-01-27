using System;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
[ExecuteInEditMode]
public class SphereTracingDebug : MonoBehaviour
{
    public Camera cam;
    
    public int marchingSteps = 50;
    public float maxDistance = 10.0f;
    public float surfaceDistance = 0.001f;

    [Range(0, 514)]public int vertexSelection = 0; // 514 because sphere mesh has 515 vertices (max index is 515-1)
    
    [Range(-0.5f, 0.5f)] private float edge = 0f; // correspond to shader _Edge properties
    private MeshFilter mesh;
    private MeshRenderer meshRenderer;
    
    private List<Vector3> circlePositions = new List<Vector3>();
    private List<float> circleRadius = new List<float>();
    private List<Vector3> vertices = new List<Vector3>();
    

    private void Start()
    {
        mesh = GetComponent<MeshFilter>();
        meshRenderer = GetComponent<MeshRenderer>();
        edge = meshRenderer.sharedMaterial.GetFloat("_Edge");
    }

    void Update()
    {
        // Sync edge with _Edge shader property
        edge = meshRenderer.material.GetFloat("_Edge");
        
        // rayOrigin = camera pos in object space
        Vector3 rayOrigin = transform.InverseTransformPoint(cam.transform.position);
        
        // rayDirection = normalize(i.hitPos - rayOrigin); vertex pos in obj space
        vertices.Clear();
        mesh.sharedMesh.GetVertices(vertices);

        // Draw sphere tracing for a selected vertex
        Vector3 rayDirection = (vertices[vertexSelection] - rayOrigin);
        rayDirection.Normalize();
        SphereCasting(rayOrigin, rayDirection);
    }

    float SphereCasting(Vector3 rayOrigin, Vector3 rayDirection)
    {
        circlePositions.Clear();
        circleRadius.Clear();
        
        float distanceOrigin = 0;
        Vector3 previousRayPos = rayOrigin;
        for (int i = 0; i < marchingSteps; i++)
        {
            Vector3 rayPosition = rayOrigin + rayDirection * distanceOrigin;
            float distanceScene = planeSDF(rayPosition);
            distanceOrigin += distanceScene;
            
            
            // Fill lists to draw Gizmo sphere
            circlePositions.Add(rayPosition);
            circleRadius.Add(distanceScene);
            
            // Draw line with random color but init random to keep the same colors everytime
            Random.InitState(i);
            Color lineCol = Random.ColorHSV();
            Debug.DrawLine(previousRayPos, rayPosition, lineCol);    
            previousRayPos = rayPosition;
            
            if (distanceScene < surfaceDistance || distanceOrigin > marchingSteps) break;
        }
        
        return distanceOrigin;
    }

    float planeSDF(Vector3 rayPosition)
    {
        return rayPosition.y - edge;
    }

    private void OnDrawGizmos()
    {
        if (vertices.Count > 0)
        {
            Gizmos.color = Color.black;
            Gizmos.DrawSphere(vertices[vertexSelection], 0.01f);

            if (circlePositions.Count > 0)
            {
                Gizmos.DrawLine(vertices[vertexSelection], circlePositions[^1]);
            }
        }
        
        for (int i = 0; i < circlePositions.Count; i++)
        {
            //Gizmos.DrawSphere(circlePositions[i], circleRadius[i]);
            Random.InitState(i);
            Color wireCol = Random.ColorHSV();
            Gizmos.color = wireCol;
            Gizmos.DrawWireSphere(circlePositions[i], circleRadius[i]);
        }
    }
}
