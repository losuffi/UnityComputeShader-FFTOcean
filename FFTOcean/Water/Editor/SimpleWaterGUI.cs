using UnityEngine;
using UnityEditor;
public class SimpleWaterGUI:ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor,properties);
        Material m= materialEditor.target as Material;
        m.EnableKeyword("SHADOWS_SCREEN");
        if(GUILayout.Button("透明状态转换"))
        {
            m.SetOverrideTag("RenderType", "Transparent");
            m.SetInt("_ZWrite", 0);
            m.DisableKeyword("_RECSHADOW");
            m.EnableKeyword("_REFRACTION");
            m.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
        }
        if(GUILayout.Button("几何状态转换"))
        {
            m.SetOverrideTag("RenderType", "");
            m.SetInt("_ZWrite", 0);
            m.renderQueue = -1;
            m.DisableKeyword("_REFRACTION");
            m.EnableKeyword("_RECSHADOW");
        }
    }
}