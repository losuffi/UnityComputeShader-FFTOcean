using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(FFTWave))]
public class FFTWaveEditor : Editor {
    public override void OnInspectorGUI() {
        base.OnInspectorGUI();
        if(GUILayout.Button("Refresh"))
        {
            (target as FFTWave).Refresh();
        }
    }
}