using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class GetReflectionMgr : MonoBehaviour {

	[SerializeField]
	private Transform SymmetricalObject;
	[SerializeField]
	private Transform plane;
    [SerializeField]
	private FFTWave wave;
    
    private Camera waterCam;
    private Camera cam;
    private RenderTexture a;
    private void OnDestroy() {
        a.Release();
        DestroyImmediate(waterCam);
    }
	public void OnRenderWater(Material mat) 
    {
        if(cam==null)
        {
            cam=Camera.current;
            cam.depthTextureMode|=DepthTextureMode.Depth;
        }
        if(waterCam==null)
        {
            waterCam=SymmetricalObject.GetComponent<Camera>();
            if(waterCam==null)
            {
                waterCam=SymmetricalObject.gameObject.AddComponent<Camera>();
            }
            waterCam.enabled=false;
        }
        if(a==null)
        {
            a=new RenderTexture(Mathf.FloorToInt(cam.pixelWidth * 0.5F),
                Mathf.FloorToInt(cam.pixelHeight * 0.5F), 24);
            a.hideFlags=HideFlags.DontSave;
            waterCam.targetTexture=a;
        }
        GL.invertCulling=true;
        Vector3 nor=plane.transform.up;
        Vector4 p=new Vector4(nor.x,nor.y,nor.z,-Vector3.Dot(nor,plane.transform.position));
        Matrix4x4 transMat=Matrix4x4.zero;
        transMat= CalculateReflectionMatrix(transMat,p);
        waterCam.worldToCameraMatrix=cam.worldToCameraMatrix*transMat;
        Vector3 nPos=cam.transform.position;
        nPos= transMat.MultiplyPoint(nPos);
        Vector3 forward=transMat.MultiplyVector(cam.transform.forward);
        waterCam.transform.position=nPos;
        waterCam.transform.rotation=cam.transform.rotation*Quaternion.FromToRotation(cam.transform.forward,forward);
        Vector4 clipPlane=CameraSpacePlane(waterCam,plane.position,nor,1);
        Matrix4x4 proj=cam.projectionMatrix;
        proj=CalculateObliqueMatrix(proj,clipPlane);
        waterCam.projectionMatrix=proj;
        waterCam.depth=-1;
        waterCam.renderingPath= RenderingPath.DeferredShading;
        waterCam.Render();
        GL.invertCulling=false;
        mat.SetMatrix("_WTC",cam.worldToCameraMatrix);
        mat.SetTexture("_MainTex",a);
        mat.SetTexture("_NormCS",wave.normalMap);
        mat.SetTexture("_DispCS",wave.displacementMap);
        mat.SetFloat("_Choppiness",wave.chopponess);
    }
    static Matrix4x4 CalculateReflectionMatrix(Matrix4x4 reflectionMat, Vector4 plane)
    {
            reflectionMat.m00 = (1.0F - 2.0F * plane[0] * plane[0]);
            reflectionMat.m01 = (- 2.0F * plane[0] * plane[1]);
            reflectionMat.m02 = (- 2.0F * plane[0] * plane[2]);
            reflectionMat.m03 = (- 2.0F * plane[3] * plane[0]);

            reflectionMat.m10 = (- 2.0F * plane[1] * plane[0]);
            reflectionMat.m11 = (1.0F - 2.0F * plane[1] * plane[1]);
            reflectionMat.m12 = (- 2.0F * plane[1] * plane[2]);
            reflectionMat.m13 = (- 2.0F * plane[3] * plane[1]);

            reflectionMat.m20 = (- 2.0F * plane[2] * plane[0]);
            reflectionMat.m21 = (- 2.0F * plane[2] * plane[1]);
            reflectionMat.m22 = (1.0F - 2.0F * plane[2] * plane[2]);
            reflectionMat.m23 = (- 2.0F * plane[3] * plane[2]);

            reflectionMat.m30 = 0.0F;
            reflectionMat.m31 = 0.0F;
            reflectionMat.m32 = 0.0F;
            reflectionMat.m33 = 1.0F;

            return reflectionMat;
    }
    static float Sgn(float a)
    {
            if (a > 0.0F)
            {
                return 1.0F;
            }
            if (a < 0.0F)
            {
                return -1.0F;
            }
            return 0.0F;
    }
    static Matrix4x4 CalculateObliqueMatrix(Matrix4x4 projection, Vector4 clipPlane)
    {
            Vector4 q = projection.inverse * new Vector4(
                Sgn(clipPlane.x),
                Sgn(clipPlane.y),
                1.0F,
                1.0F
                );
            Vector4 c = clipPlane * (2.0F / (Vector4.Dot(clipPlane, q)));
            // third row = clip plane - fourth row
            projection[2] = c.x - projection[3];
            projection[6] = c.y - projection[7];
            projection[10] = c.z - projection[11];
            projection[14] = c.w - projection[15];

            return projection;
    }
    Vector4 CameraSpacePlane(Camera cam, Vector3 pos, Vector3 normal, float sideSign)
    {
            Vector3 offsetPos = pos + normal*0.07f;
            Matrix4x4 m = cam.worldToCameraMatrix;
            Vector3 cpos = m.MultiplyPoint(offsetPos);
            Vector3 cnormal = m.MultiplyVector(normal).normalized * sideSign;
            return new Vector4(cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot(cpos, cnormal));
    }
}