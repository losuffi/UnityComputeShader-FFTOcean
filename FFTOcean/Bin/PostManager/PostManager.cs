using UnityEngine;
using System.Collections.Generic;
using UnityEngine.Rendering;
using System;

[RequireComponent(typeof(Camera)),DisallowMultipleComponent]
public class PostManager : MonoBehaviour {

    private RenderTexture currentPost;
    private RenderTexture initPost;
    private RenderTexture depthPost;
    private RenderTexture normalPost;
    private List<PostAgent> agentList;

    private static PostManager instantiete;
    public static PostManager Instantiete{get{return instantiete;}}
    private Camera cam;

    public class PostAgent
    {
        public int Priority;
        public delegate void TriggerFunc();
        public TriggerFunc Trigger;
        private RenderTexture buffer;
        public RenderTexture Buf
        {
            get{return buffer;}
        }
        public PostAgent(TriggerFunc func,RenderTexture buf,int p=0)
        {
            this.Trigger=func;
            this.Priority=p;
            this.buffer=buf;
        }
    }
    public RenderTexture CurrentBuffer
    {
        get
        {
            if(currentPost==null)
            {
                CreateCurrentBuffer();
            }
            return currentPost;
        }
    }
    public RenderTexture InitPost
    {
        get
        {
            if(initPost==null)
            {
                CreateInitBuffer();
            }
            return initPost;
        }
    }
    public RenderTexture DepthPost
    {
        get
        {
            if(depthPost==null)
            {
                CreateDepthBuffer();
            }
            return depthPost;
        }
    }

   

    public RenderTexture NormalPost
    {
        get
        {
            return normalPost;
        }
    }
    public void ReleaseAllBuffer()
    {
        currentPost.Release();
        currentPost=null;
        initPost.Release();
        initPost=null;
        depthPost.Release();
        depthPost=null;
        normalPost.Release();
        normalPost=null;
        agentList=null;
        GC.Collect();
    }
    private void OnDisable() {
        ReleaseAllBuffer();
    }
    public void PushInPostStack(PostAgent agent)   
    {
        if(agentList==null)
        {
            agentList=new List<PostAgent>(10);
        }
        int index=0;
        for(int i=0;i<agentList.Count;i++)
        {
            if(agentList[i].Priority<agent.Priority)
            {
                break;
            }
            index++;
        }
        agentList.Insert(index,agent);
    }
    private void OnEnable() 
    {
        if(instantiete==null)
            instantiete=this;       
        cam=GetComponent<Camera>();
    }


    private void CreateCurrentBuffer()
    {
        currentPost=new RenderTexture(Screen.width,Screen.height,0,RenderTextureFormat.ARGB32);
        currentPost.enableRandomWrite=true;
        currentPost.Create();
    }
    private void CreateInitBuffer()
    {
        initPost=new RenderTexture(Screen.width,Screen.height,0,RenderTextureFormat.ARGB32);
        initPost.enableRandomWrite=true;
        initPost.Create();
    }
    private void CreateDepthBuffer()
    {
        cam.depthTextureMode|=DepthTextureMode.Depth;
        depthPost=new RenderTexture(Screen.width,Screen.height,24);
        depthPost.enableRandomWrite=true;
        depthPost.Create();
        CommandBuffer buf =new CommandBuffer();
        buf.name="buffer";
        cam.AddCommandBuffer(CameraEvent.AfterDepthTexture,buf);
        buf.Clear();
        buf.Blit(BuiltinRenderTextureType.Depth,depthPost);
    }
    private void OnRenderImage(RenderTexture src, RenderTexture dest) 
    {
        initPost=src;       
        if(currentPost==null||agentList==null)
        {
            Graphics.Blit(initPost,dest);
            return;
        }
        Graphics.Blit(initPost,currentPost);
        for(int i=0;i<agentList.Count;i++)
        {
            Graphics.Blit(agentList[i].Buf,currentPost);
            if(agentList[i].Trigger!=null)
                agentList[i].Trigger();
        }
        Graphics.Blit(currentPost,dest);
    }
}