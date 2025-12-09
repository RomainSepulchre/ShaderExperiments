using UnityEngine;

[ExecuteInEditMode] // Allow to preview change in edit mode
public class ShaderReplacementController : MonoBehaviour
{
    public Shader _replacementShader;

    void OnEnable()
    {
        if(_replacementShader != null)
        {
            // All the shader that match the render type of the replacement shader will be replaced by our replacement shader
            GetComponent<Camera>().SetReplacementShader(_replacementShader, "RenderType");
        }
    }

    void OnDisable()
    {
        // Reset to default shader
        GetComponent<Camera>().ResetReplacementShader();
    }
}
