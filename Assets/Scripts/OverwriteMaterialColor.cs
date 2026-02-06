using UnityEngine;

[ExecuteInEditMode]
public class OverwriteMaterialColor : MonoBehaviour
{
    public Color color;
    private Renderer rend;
    private MaterialPropertyBlock propBlock;

    void Start()
    {
        rend = GetComponent<Renderer>();
        propBlock = new MaterialPropertyBlock();
        
        // Get the current property values from the renderer
        rend.GetPropertyBlock(propBlock); 
        
        // Set the new color (the property name might differ in custom shaders)
        propBlock.SetColor("_Color", color); 
        
        // Apply the property block to the renderer
        rend.SetPropertyBlock(propBlock); 
    }
}