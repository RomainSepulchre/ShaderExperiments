using System;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
[RequireComponent(typeof(MeshFilter))]
public class PathTracedObject : MonoBehaviour
{
    public Color albedo = Color.dimGray;
    [Range(0f,1f)] public float specular = 0.65f;
    [Range(0f,1f)] public float smoothness = 0.9f;
    [ColorUsage(true,true)] public Color emission = Color.black;
        
    private void OnEnable()
    {
        PathTracingController.RegisterObject(this);
    }

    private void OnDisable()
    {
        PathTracingController.UnregisterObject(this);
    }
}
