using System;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class ConstructiveSolidGeometryController : MonoBehaviour
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

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!RaymarchMaterial)
        {
            Graphics.Blit(source, destination);
            return;
        }
        
        RaymarchMaterial.SetMatrix("_CamFrustumMatrix", GetCameraFrustum(Camera));
        RaymarchMaterial.SetMatrix("_CamToWorldMatrix", Camera.cameraToWorldMatrix);
        RaymarchMaterial.SetVector("_CamWorldSpace", Camera.transform.position);
        
        RenderTexture.active = destination;
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
}
