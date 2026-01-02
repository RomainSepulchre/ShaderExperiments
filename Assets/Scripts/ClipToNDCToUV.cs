using UnityEngine;

public class ClipToNDCToUV : MonoBehaviour
{
    public Vector4 clipPos;

    [Space(30)]
    [Header("Intermediate value")]
    public Vector2 ndc;
    public Vector4 computedScreenPos;
    
    [Space(30)]
    [Header("Result")]
    public Vector2 uvNdcRemapped;
    public Vector2 uvScreenPosNdc;
    
    void Start()
    {
        uvNdcRemapped = NDCToUV(ConvertClipPosToNDC(clipPos));

        uvScreenPosNdc = ScreenPosToUV(ComputeScreenPos(clipPos));
    }
    
    // Convert clip pos to NDC values
    private Vector4 ConvertClipPosToNDC(Vector4 _clipPos)
    {
        Vector4 clipAsNdc = new Vector4( _clipPos.x/_clipPos.w , _clipPos.y/_clipPos.w, _clipPos.z/_clipPos.w, _clipPos.w );
        ndc = clipAsNdc;
        return clipAsNdc;
    }
    
    // Remap NDC value from [-1,1] to [0,1]
    private Vector2 NDCToUV(Vector4 ndcPos)
    {
        float x = (ndcPos.x + 1) / 2;
        float y = (ndcPos.y + 1) / 2;
        return new Vector2(x, y);
    }
    
    // Remap clip position from [-w,w] to [0,w]
    private Vector4 ComputeScreenPos(Vector4 _clipPos)
    {
        Vector4 o = _clipPos / 2;

        o.x = o.x + o.w;
        o.y = o.y + o.w;
        o.z = _clipPos.z;
        o.w = _clipPos.w;

        computedScreenPos = o;

        return o;
    }
    
    // Divide X,Y by W to remap from [0,w] to [0,1]
    private Vector2 ScreenPosToUV(Vector4 _screenPos)
    {
        return new Vector2(_screenPos.x/_screenPos.w, _screenPos.y/_screenPos.w);
    }
    
}
