using UnityEngine;
[RequireComponent(typeof(MeshRenderer))]
public class ProjectorShadowAgent : MonoBehaviour {
    [SerializeField]
    private ProjectorShadow mgr;
    private void OnWillRenderObject() {
        if(mgr==null) return;
        mgr.UpdateShadow();
    }
}