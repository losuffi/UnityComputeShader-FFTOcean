using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
[RequireComponent(typeof(MeshRenderer))]
public class ReflectionSurface : MonoBehaviour {

	[SerializeField]
	private GetReflectionMgr center;

	private Material m;
	private void OnWillRenderObject() {
		if(center==null)
		{
			return;
		}
		if(m==null)
		{
			m=GetComponent<MeshRenderer>().sharedMaterial;
		}
		center.OnRenderWater(m);
	}
}
