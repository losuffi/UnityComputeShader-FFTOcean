using UnityEngine;

public class CamController : MonoBehaviour {
    [SerializeField]
    private float Speed;
    [SerializeField]
    private float rotaSpeed;
    private bool IsEsc=false;
    private void Update() {
        if(Input.GetKeyDown(KeyCode.Escape))
        {
            IsEsc=!IsEsc;
        }
        Cursor.visible=!IsEsc;
        
        if(!IsEsc)
        {
            Cursor.lockState= CursorLockMode.Confined;
            return;
        }
        Cursor.lockState= CursorLockMode.Locked;
        transform.rotation=(Quaternion.AngleAxis(Input.GetAxis("Mouse X")*rotaSpeed*Time.deltaTime,Vector3.up)*Quaternion.AngleAxis(Input.GetAxis("Mouse Y")*rotaSpeed*Time.deltaTime,Vector3.left))*transform.rotation;
        if(Input.GetKey(KeyCode.W))
        {
            transform.position+=Speed*Time.deltaTime*transform.forward;
        }
        if(Input.GetKey(KeyCode.S))
        {
            transform.position-=Speed*Time.deltaTime*transform.forward;
        }
    }
}