using UnityEngine;
using UnityEngine.Rendering;
public class ShadowCollector : MonoBehaviour {
    [SerializeField]
    private Light _light;
    [SerializeField]
    private MeshRenderer[] targetMats;
    
    [HideInInspector]
    public RenderTexture shadowmap;
    private CommandBuffer cb;

    private void OnEnable() {
        shadowmap=new RenderTexture(2048,2048,0,RenderTextureFormat.RFloat);
        shadowmap.enableRandomWrite=true;
        shadowmap.useMipMap=false;
        var bufs=_light.GetCommandBuffers(LightEvent.AfterScreenspaceMask);
        foreach(var buf in bufs)
        {
            if(buf.name.Equals("CustomShadow")) return;
        }
        cb=new CommandBuffer();
        cb.name="CustomShadow";
        _light.AddCommandBuffer(LightEvent.AfterShadowMap,cb);
        UpdateBuffer();
    }
    private void OnDisable() {
        shadowmap.Release();
    }
    private void UpdateBuffer() {
        cb.Clear();
        cb.SetShadowSamplingMode(BuiltinRenderTextureType.CurrentActive,ShadowSamplingMode.RawDepth);
        cb.Blit(BuiltinRenderTextureType.CurrentActive,shadowmap);
    }
}