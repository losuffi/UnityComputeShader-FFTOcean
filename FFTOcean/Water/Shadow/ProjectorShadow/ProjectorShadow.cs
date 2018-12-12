using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[RequireComponent(typeof(Projector))]
public class ProjectorShadow: MonoBehaviour {
	[SerializeField]
	private LayerMask renderLayer;
	[SerializeField]
	private ComputeShader computKernel;
	[SerializeField]
	private int BlurSize=1;
	[SerializeField]
	private int BufferSize=512;
	[SerializeField]
	private int SampleCount=1;
	[SerializeField]
	[Range(0,1f)]
	private float Strengthess=1;
	[HideInInspector]
	public RenderTexture shadowMapMsg;
	[SerializeField]
	private MeshRenderer mesh;
	[SerializeField]
	private Vector3 Offset;
	private RenderTexture renderTemp;
	private RenderTexture shadowMap;
	private Projector m_projector;
	private Camera m_Cam;
	
	private void OnEnable() {
		m_projector=GetComponent<Projector>();
		shadowMapMsg=null;
		m_Cam=gameObject.GetComponent<Camera>();
	}
	public void UpdateShadow() {
		OnRenderShadowMap();
		OnProjectorShadow();
	}
	public void OnRenderShadowMap()
	{
		if(shadowMapMsg==null)
		{
			CreateShadowBuffer();
		}
		if(m_Cam==null)
		{
			CreateShadowCam();
		}
		m_Cam.Render();
		int Kernel=computKernel.FindKernel("ComShadowMap");
		computKernel.SetTexture(Kernel,"inp",shadowMapMsg);
		computKernel.SetTexture(Kernel,"shadowM",shadowMap);
		computKernel.Dispatch(Kernel,BufferSize/8,BufferSize/8,1);
		Kernel=computKernel.FindKernel("BlurShadowMapX");
		computKernel.SetTexture(Kernel,"input",shadowMap);
		computKernel.SetTexture(Kernel,"shadowMap",renderTemp);
		computKernel.SetInt("Length",BlurSize);
		computKernel.SetInt("SCount",SampleCount);
		computKernel.SetFloat("Strengthess",Strengthess);
		computKernel.Dispatch(Kernel,BufferSize/1024,BufferSize,1);

		Kernel=computKernel.FindKernel("BlurShadowMapY");
		computKernel.SetTexture(Kernel,"input",renderTemp);
		computKernel.SetTexture(Kernel,"shadowMap",shadowMap);
		computKernel.SetInt("Length",BlurSize);
		computKernel.SetInt("SCount",SampleCount);
		computKernel.SetFloat("Strengthess",Strengthess);
		computKernel.Dispatch(Kernel,BufferSize,BufferSize/1024,1);
		Matrix4x4 transMat= Matrix4x4.TRS((Offset+Vector3.one)*0.5f,Quaternion.identity,Vector3.one*0.5f) * m_Cam.projectionMatrix*m_Cam.worldToCameraMatrix;
		Shader.SetGlobalMatrix("shadow_Projector",transMat);
	} 

    private void CreateShadowCam()
    {
		m_Cam=gameObject.AddComponent<Camera>();
		m_Cam.enabled=false;
		m_Cam.targetTexture=shadowMapMsg;
		m_Cam.farClipPlane=m_projector.farClipPlane;
		m_Cam.fieldOfView=m_projector.fieldOfView;
		m_Cam.nearClipPlane=m_projector.nearClipPlane;
		m_Cam.cullingMask=renderLayer.value;
		m_Cam.clearFlags=CameraClearFlags.Color;
		m_Cam.backgroundColor=Color.black;
		m_Cam.depth=-1;
        m_Cam.renderingPath= RenderingPath.DeferredShading;
		m_Cam.orthographic=m_projector.orthographic;
		m_Cam.orthographicSize=m_projector.orthographicSize;
    }

    private void CreateShadowBuffer()
    {
		shadowMapMsg=new RenderTexture(BufferSize,BufferSize,0,RenderTextureFormat.RHalf);
		shadowMapMsg.enableRandomWrite=true;
		shadowMapMsg.filterMode= FilterMode.Bilinear;
		shadowMapMsg.useMipMap=false;
		shadowMapMsg.hideFlags=HideFlags.DontSave;
		shadowMapMsg.enableRandomWrite=true;
		shadowMapMsg.Create();
		shadowMap=new RenderTexture(BufferSize,BufferSize,0,RenderTextureFormat.ARGB32);
		shadowMap.enableRandomWrite=true;
		shadowMap.filterMode= FilterMode.Bilinear;
		shadowMap.useMipMap=false;
		shadowMap.enableRandomWrite=true;
		shadowMap.Create();
		renderTemp=new RenderTexture(BufferSize,BufferSize,0,RenderTextureFormat.ARGB32);
		renderTemp.enableRandomWrite=true;
		renderTemp.filterMode= FilterMode.Bilinear;
		renderTemp.useMipMap=false;
		renderTemp.enableRandomWrite=true;
		renderTemp.Create();
    }

    public void OnProjectorShadow()
	{
		if(mesh==null)
		{
			m_projector.enabled=true;
			m_projector.material.SetTexture("_ShadowMap",shadowMap);
		}
		else
		{
			m_projector.enabled=false;
			mesh.sharedMaterial.SetTexture("_ShadowMap",shadowMap);
		}
	}
}
