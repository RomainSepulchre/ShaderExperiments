using System;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class ConstructiveSolidGeometryController : SceneViewFilter
{
    public Shader shader;
    

    public Material RaymarchMaterial
    {
        get
        {
            if (!_raymarchMaterial && shader)
            {
                _raymarchMaterial = new Material(shader);
                _raymarchMaterial.hideFlags = HideFlags.HideAndDontSave;
            }
            return _raymarchMaterial;
        }
    }
    private Material _raymarchMaterial;

    public Camera Camera
    {
        get
        {
            if (!_camera)
            {
                _camera = GetComponent<Camera>();
            }
            return _camera;
        }
    }
    private Camera _camera;
    
    public float maxDistance;

    [Range(0f,1f)]public float ShapesInterpolation = 0.5f;
    public Vector4 Sphere1;
    public Vector4 Sphere2;
    public Vector3 BoxPosition;
    public Vector3 BoxSize;

    private void OnEnable()
    {
        Camera.depthTextureMode = DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!RaymarchMaterial)
        {
            Graphics.Blit(source, destination);
            return;
        }
        
        RaymarchMaterial.SetMatrix("_CamFrustumMatrix", GetCameraFrustum(Camera));
        RaymarchMaterial.SetMatrix("_CamToWorldMatrix", Camera.cameraToWorldMatrix);
        RaymarchMaterial.SetFloat("_MaxDistance", maxDistance);
        RaymarchMaterial.SetFloat("_ShapesInterpolation", ShapesInterpolation);
        RaymarchMaterial.SetVector("_Sphere1", Sphere1);
        RaymarchMaterial.SetVector("_Sphere2", Sphere2);
        RaymarchMaterial.SetVector("_BoxPosition", BoxPosition);
        RaymarchMaterial.SetVector("_BoxSize", BoxSize);
        
        RenderTexture.active = destination;
        RaymarchMaterial.SetTexture("_MainTex", source);
        
        GL.PushMatrix();
        GL.LoadOrtho();
        RaymarchMaterial.SetPass(0);
        GL.Begin(GL.QUADS);
        
        // Frustum Bottom left corner
        GL.MultiTexCoord2(0,0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f);
        
        // Frustum Bottom Right corner
        GL.MultiTexCoord2(0,1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f);
        
        // Frustum Top Right corner
        GL.MultiTexCoord2(0,1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);
        
        // Frustum Top left corner
        GL.MultiTexCoord2(0,0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);
        
        GL.End();
        GL.PopMatrix();
    }

    private Matrix4x4 GetCameraFrustum(Camera cam)
    {
        Matrix4x4 frustum = Matrix4x4.identity;
        float fov = Mathf.Tan((cam.fieldOfView * 0.5f) * Mathf.Deg2Rad); // Get camera FOV and convert it from degrees to radians

        Vector3 goUp = Vector3.up * fov;
        Vector3 goRight = Vector3.right * fov * cam.aspect;
        
        Vector3 TopLeft = (-Vector3.forward - goRight) + goUp;
        Vector3 TopRight = (-Vector3.forward + goRight) + goUp;
        Vector3 BottomRight = (-Vector3.forward + goRight) - goUp;
        Vector3 BottomLeft = (-Vector3.forward - goRight) - goUp;
        
        frustum.SetRow(0, TopLeft);
        frustum.SetRow(1, TopRight);
        frustum.SetRow(2, BottomRight);
        frustum.SetRow(3, BottomLeft);
        
        return frustum;
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.green;
        Gizmos.DrawCube(new Vector3(BoxPosition.x, BoxPosition.y, BoxPosition.z), BoxSize * 2);
        Gizmos.DrawWireCube(new Vector3(BoxPosition.x, BoxPosition.y, BoxPosition.z), BoxSize * 2);
        Gizmos.color = Color.red;
        Gizmos.DrawSphere(new Vector3(Sphere1.x, Sphere1.y, Sphere1.z), Sphere1.w);
        Gizmos.DrawWireSphere(new Vector3(Sphere1.x, Sphere1.y, Sphere1.z), Sphere1.w);
        Gizmos.color = Color.blue;
        Gizmos.DrawSphere(new Vector3(Sphere2.x, Sphere2.y, Sphere2.z), Sphere2.w);
        Gizmos.DrawWireSphere(new Vector3(Sphere2.x, Sphere2.y, Sphere2.z), Sphere2.w);
        
    }
}
