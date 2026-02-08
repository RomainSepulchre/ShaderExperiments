using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Serialization;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class ConstructiveSolidGeometryController : SceneViewFilter
{
    [Header("Required")]
    public Shader shader;
    public Light mainLight;

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
    
    [Header("Rendering")]
    public float maxDistance;
    public Color ShapesColor = Color.white;
    public int maxIteration = 128;

    public enum ShadowModes
    {
        HardShadow = 0,
        SoftShadow = 1
    }
    [Header("Shadows")]
    public ShadowModes ShadowMode;
    [Range(0f,10f)] public float ShadowIntensity;
    public Vector2 ShadowDistance;
    [Range(1f,128f)] public float ShadowPenumbra;
    
    // [Header("Repeat pattern")]
    // [Range(0f,1f)]public float ShapesInterpolation = 0.5f;
    // public Vector3 RepeatInterval = new Vector3(1f, 1f, 1f);
    // public Vector4 Sphere1;
    // public Vector4 Sphere2;
    // public Vector3 BoxPosition;
    // public Vector3 BoxSize;
    
    [Space(10)]
    [Header("Demo Controls")]
    public bool AnimateDemo = true;
    public float AnimationSpeed = 1f;
    public Vector3 DemoPosition;
    public Vector3 DemoRotation;
    public float DemoScale;
    [Range(0f,1f)]public float DemoSmooth = 0.5f;
    [Range(-0.25f,0.25f)]public float DemoCutOffset;
    public float DemoSymmetryOffset = 0.25f;
    public float DemoTwist = 2f;
    public float DemoBend = 2f;
    public float DemoDisplacement = 1f;
    
    [Header("Debug")]
    public Vector4 DebugParams;
    public enum SDFAxis
    {
        X = 0,
        Y = 1,
        Z = 2
        //MinusX = 3,
        //MinusY = 4,
        //MinusZ = 5
    }
    public SDFAxis DebugAxis = SDFAxis.Y;
    
    // Keyword that match with ShadowModes enum
    
    private LocalKeyword HardShadowKeyword;
    private LocalKeyword SoftShadowKeyword;

    private void OnEnable()
    {
        Camera.depthTextureMode = DepthTextureMode.Depth;
        
        // Note: when doing this at Start(), I had a "local keyword are not using same shader" error, maybe because start() is called too late (or only in specific condition) with [ExecuteInEditMode] ?
        // -> still happens with OnEnable but less recurrent than with start: Ensure they are valid in OnRenderImage.
        SetLocalKeyword();
    }

    void SetLocalKeyword()
    {
        if (RaymarchMaterial != null)
        {
            HardShadowKeyword = new LocalKeyword(RaymarchMaterial.shader, "_SHADOWMODE_HARDSHADOW");
            SoftShadowKeyword = new LocalKeyword(RaymarchMaterial.shader, "_SHADOWMODE_SOFTSHADOW");
        }
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
        RaymarchMaterial.SetInt("_MaxIteration", maxIteration);
        RaymarchMaterial.SetColor("_ShapesColor", ShapesColor);
        RaymarchMaterial.SetColor("_LightColor", mainLight.color);
        RaymarchMaterial.SetFloat("_LightIntensity", mainLight.intensity);
        if (!HardShadowKeyword.isValid || !SoftShadowKeyword.isValid) SetLocalKeyword(); // Ensure local keyword are set in case onEnable was called before in editor => doesn't work either, they are considered valid
        RaymarchMaterial.SetKeyword(HardShadowKeyword, ShadowMode == ShadowModes.HardShadow);
        RaymarchMaterial.SetKeyword(SoftShadowKeyword, ShadowMode ==  ShadowModes.SoftShadow);
        RaymarchMaterial.SetFloat("_ShadowIntensity", ShadowIntensity);
        RaymarchMaterial.SetVector("_ShadowDistance", ShadowDistance);
        RaymarchMaterial.SetFloat("_ShadowPenumbra", ShadowPenumbra);
        
        // RaymarchMaterial.SetFloat("_ShapesInterpolation", ShapesInterpolation);
        // RaymarchMaterial.SetVector("_RepeatInterval", RepeatInterval);
        // RaymarchMaterial.SetVector("_Sphere1", Sphere1);
        // RaymarchMaterial.SetVector("_Sphere2", Sphere2);
        // RaymarchMaterial.SetVector("_BoxPosition", BoxPosition);
        // RaymarchMaterial.SetVector("_BoxSize", BoxSize);
        
        RaymarchMaterial.SetInt("_AnimateDemo", AnimateDemo ? 1 : 0);
        RaymarchMaterial.SetFloat("_AnimationSpeed", AnimationSpeed);
        RaymarchMaterial.SetVector("_DemoPos", DemoPosition);
        RaymarchMaterial.SetVector("_DemoRot", DemoRotation);
        RaymarchMaterial.SetFloat("_DemoScale", DemoScale);
        RaymarchMaterial.SetFloat("_DemoSmooth", DemoSmooth);
        RaymarchMaterial.SetFloat("_DemoCutOffset", DemoCutOffset);
        RaymarchMaterial.SetFloat("_DemoSymOffset", DemoSymmetryOffset);
        RaymarchMaterial.SetFloat("_DemoTwist", DemoTwist);
        RaymarchMaterial.SetFloat("_DemoBend", DemoBend);
        RaymarchMaterial.SetFloat("_DemoDisplacement", DemoDisplacement);
            
        RaymarchMaterial.SetVector("_DebugParams", DebugParams);
        RaymarchMaterial.SetInt("_DebugAxis", (int)DebugAxis);
        
        
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
        // Gizmos.color = Color.green;
        // Gizmos.DrawCube(new Vector3(BoxPosition.x, BoxPosition.y, BoxPosition.z), BoxSize * 2);
        // Gizmos.DrawWireCube(new Vector3(BoxPosition.x, BoxPosition.y, BoxPosition.z), BoxSize * 2);
        // Gizmos.color = Color.red;
        // Gizmos.DrawSphere(new Vector3(Sphere1.x, Sphere1.y, Sphere1.z), Sphere1.w);
        // Gizmos.DrawWireSphere(new Vector3(Sphere1.x, Sphere1.y, Sphere1.z), Sphere1.w);
        // Gizmos.color = Color.blue;
        // Gizmos.DrawSphere(new Vector3(Sphere2.x, Sphere2.y, Sphere2.z), Sphere2.w);
        // Gizmos.DrawWireSphere(new Vector3(Sphere2.x, Sphere2.y, Sphere2.z), Sphere2.w);
        
    }
}
