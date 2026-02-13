using System;
using UnityEngine;

[ExecuteInEditMode]
public class NoiseShaderController : MonoBehaviour
{
    [Header("Required")]
    public Shader shader;
    
    public Material WarpMaterial
    {
        get
        {
            if (!_warpMaterial && shader)
            {
                _warpMaterial = new Material(shader);
                _warpMaterial.hideFlags = HideFlags.HideAndDontSave;
            }
            return _warpMaterial;
        }
    }
    private Material _warpMaterial;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!WarpMaterial)
        {
            Graphics.Blit(source, destination);
            return;
        }
        
        Graphics.Blit(source, destination, WarpMaterial);
        
        //RenderTexture.active = destination;
        //WarpMaterial.SetTexture("_MainTex", source);
    }
    
}
