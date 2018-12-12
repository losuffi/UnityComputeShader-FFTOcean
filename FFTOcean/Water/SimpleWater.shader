
Shader "ArtStandard/Environment/Water/Simple"
{
    Properties
    {
        _Color("Refraction Color",Color) = (0,0.15,0.115,1)
        _ReflectColor("Reflection Color",Color)=(0,0.14,0.224,1)
        _SpecColor("Specular Color",Color)=(0,0.14,0.224,1)
        _BoardColor("Board Color",Color)=(0,0.14,0.224,1)
        _BoardTex("Board Tex",2D)="white"{}
        _LightReflectionColor("Light Front Color",Color)=(0.641,0.775,0.121,1)
        _LightReflectionBackColor("Light Back Color",Color)=(0.141,0.175,0.121,1)
        _MainTex("Main Tex",2D)= "white"{}
        _WaveMap("Wave Map",2D)= "bump"{}
        _WaveHeight("Wave Height",2D)="black"{}
        _WaveSpeed("Wave Speed",Vector)=(0.0001,0.0001,0.5,0.5)
        _Distortion("Reflection Distortion",Range(0,100))=10
        _RefractionDistortion("Refraction Distortion",Range(0,100))=5
        _FresnelMax("FresnelMax",Range(0,1))=0.5
        _ShadowIntensity ("ShadowIntensity",Range(0,1))=0.5
        //_WaveScale("Wave Scale",Range(0.1,100))=3
        _JitterDepthScale("Jitter Scale",Range(0,5))=0.5
        _LightReflectionScale("Light Scale",Range(0,40))=10
        _ColorAlpha("Color Alpha",Range(0,1))=0.3
        _LightSepcularScale("Light Specular Scale",Range(0,40))=12
        _TessellationScale("Tessellation Scale",Range(0,1000))=190
        _BiTangent("BiTangent",Vector)=(0.71,1,0.1,0)
        _AlignmentNormal("Alignment Normal",Vector)=(0,1,0,0)
        _AlignmentLight("Alignment Light",Vector)=(1.63,1,0.29,0)
        _RefractionAlpha("Refraction Alpha",Range(0.001,1))=0.3
    }
    SubShader
    {
        Tags {"LightMode"="ForwardBase" "Queue"="Transparent" "RenderType"="Opaque"}
        GrabPass{"_RefractionTex"}
        Pass
        {
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma hull hs
            #pragma domain ds

            #include "../Bin/Tessellation.cginc"
            #include "UnityStandardCore.cginc"
            #pragma multi_compile_fwdbase nolightmap
            #pragma shader_feature _RECSHADOW
            sampler2D _WaveMap,_WaveHeight,_BoardTex;
            float4 _WaveMap_ST,_WaveHeight_ST;
            fixed4 _ReflectColor,_LightReflectionColor,_LightReflectionBackColor,_BoardColor;
            float _JitterDepthScale,_Distortion,_RefractionDistortion,_ShadowIntensity,_FresnelMax,_WaveScale,_LightReflectionScale,_LightSepcularScale,_ColorAlpha,_RefractionAlpha;
            sampler2D _RefractionTex;
            sampler2D _CameraDepthTexture;
            float4 _RefractionTex_TexelSize,_BiTangent,_WaveSpeed,_AlignmentNormal,_AlignmentLight;
            float4x4 _WTC;
            
            //From CS
            sampler2D _DispCS,_NormCS;
            float _Choppiness;

            struct v2f
            {
                float4 pos:SV_POSITION;
                float4 screenPos:TEXCOORD0;
                float4 uv:TEXCOORD1;
                float4 tangentToWorld[3]:TEXCOORD2;
                SHADOW_COORDS(5)
            };
            // inline float getHeight(float4 nuv,float2 speed)
            // {
            //     float height= tex2Dlod(_WaveHeight,nuv/128+float4(speed*100,0,0)).r*_WaveScale*1;
            //     height+= tex2Dlod(_WaveHeight,nuv/64+float4(speed*50,0,0)).r*_WaveScale*0.5;
            //     height+= tex2Dlod(_WaveHeight,nuv/32+float4(speed*25,0,0)).r*_WaveScale*0.25;
            //     height+= tex2Dlod(_WaveHeight,nuv/16+float4(speed*12.5,0,0)).r*_WaveScale*0.2;
            //     height+= tex2Dlod(_WaveHeight,nuv*2+float4(speed/2,0,0)).r*_WaveScale*0.1;
            //     height+= tex2Dlod(_WaveHeight,nuv*4+float4(speed/4,0,0)).r*_WaveScale*0.05;
            //     height+= tex2Dlod(_WaveHeight,nuv*8+float4(speed/8,0,0)).r*_WaveScale*0.025;
            //     height+= tex2Dlod(_WaveHeight,nuv*16+float4(speed/16,0,0)).r*_WaveScale*0.0125;
            //     height+= tex2Dlod(_WaveHeight,nuv*32+float4(speed/32,0,0)).r*_WaveScale*0.0125;
            //     height+= tex2Dlod(_WaveHeight,nuv*64+float4(speed/64,0,0)).r*_WaveScale*0.0125;
            //     height+= tex2Dlod(_WaveHeight,nuv*128+float4(speed/128,0,0)).r*_WaveScale*0.0125;
            //     height+= tex2Dlod(_WaveHeight,nuv*256+float4(speed/256,0,0)).r*_WaveScale*0.0125;
            //     height+= tex2Dlod(_WaveHeight,nuv*512+float4(speed/512,0,0)).r*_WaveScale*0.0125;
            //     //height+=tex2Dlod(_WaveHeight,nuv+float4(-speed,0,0)).r*_WaveScale;
            //     //height+=tex2Dlod(_WaveHeight,nuv*2+float4(-speed,0,0)).r*_WaveScale/2;
            //     //height+=tex2Dlod(_WaveHeight,nuv*2+float4(speed,0,0)).r*_WaveScale/2;
            //     // height+=tex2Dlod(_WaveHeight,nuv*4+float4(speed,0,0)).r*_WaveScale;
            //     // height+=tex2Dlod(_WaveHeight,nuv*4+float4(-speed,0,0)).r*_WaveScale;
            //     // height+=tex2Dlod(_WaveHeight,nuv*16+float4(speed,0,0)).r*_WaveScale;
            //     // height+=tex2Dlod(_WaveHeight,nuv*16+float4(-speed,0,0)).r*_WaveScale;
            //     // height+=tex2Dlod(_WaveHeight,nuv*8+float4(-speed,0,0)).r*_WaveScale;
            //     // height+=tex2Dlod(_WaveHeight,nuv*8+float4(speed,0,0)).r*_WaveScale;
            //     // height+=tex2Dlod(_WaveHeight,nuv*32+float4(speed,0,0)).r*_WaveScale;
            //     // height+=tex2Dlod(_WaveHeight,nuv*32+float4(-speed,0,0)).r*_WaveScale;
            //     return height;
            // }
            inline float3 MovePos(float4 nuv)
            {
                return tex2Dlod(_DispCS,nuv).xyz*_Choppiness;
            }
            // inline float3 getBump(float4 buv,float2 speed)
            // {
            //     buv.xy+=speed;
            //     float3 b= UnpackNormal(tex2D(_WaveMap,buv.xy)).rgb;
            //     return b;
            // }
            inline float4 HeightPoint(float4 uv,float4 oPos)
            {
                float4 wpos=mul(unity_ObjectToWorld,oPos);   
                float2 speed=_Time.y*_WaveSpeed.xy;
                float4 nuv=uv+float4(speed,0,0);
                wpos.xyz+=MovePos(uv);
                return mul(unity_WorldToObject,wpos);
            }
            v2f TessellationVertex(TVD v)
            {
                v2f o;
                o.uv.xy=TRANSFORM_TEX(v.uv1,_WaveHeight);
                o.uv.zw=TRANSFORM_TEX(v.uv1,_WaveMap);
                float3 wn=UnityObjectToWorldNormal(v.normal);
                float4 huv=float4(o.uv.xy,0,0);
                float3 tangent=v.tangent.xyz;
                float4 opos=HeightPoint(huv,v.vertex);
                o.pos=UnityObjectToClipPos(opos);
                o.screenPos=ComputeScreenPos(o.pos);
                float4 tangentworld=float4(UnityObjectToWorldDir(tangent),v.tangent.w);
                float3x3 tTw=CreateTangentToWorldPerVertex(wn,tangentworld.xyz,-tangentworld.w);
                float3 wpos=mul(unity_ObjectToWorld,v.vertex);
                o.tangentToWorld[0].xyz=tTw[0];
                o.tangentToWorld[1].xyz=tTw[1];
                o.tangentToWorld[2].xyz=tTw[2];
                o.tangentToWorld[0].w=wpos.x;
                o.tangentToWorld[1].w=wpos.y;
                o.tangentToWorld[2].w=wpos.z;
                TRANSFER_SHADOW(o);
                return o;
            }
            [UNITY_domain("tri")]
            v2f ds(TessellationFactors factors,
                    OutputPatch<TVD,3> patch,
                    float3 barycentricCoordinates:SV_DomainLocation)
            {
                TVD data;
                DS_PROGRAM_INTERPOLATE(vertex)
                DS_PROGRAM_INTERPOLATE(normal)
                DS_PROGRAM_INTERPOLATE(tangent)
                DS_PROGRAM_INTERPOLATE(uv)
                DS_PROGRAM_INTERPOLATE(uv1)
                DS_PROGRAM_INTERPOLATE(uv2)
                return TessellationVertex(data);
            }
            
            inline float WorldPostionToLinearDepth(float3 wpos)
            {
                float3 camPos=mul(unity_WorldToCamera,float4(wpos,1)).xyz;
                float d=(camPos.z-_ProjectionParams.y)/(_ProjectionParams.z - _ProjectionParams.y);
                return d;
            }
            inline float WorldPostionToLinearEyeDepth(float3 wpos)
            {
                float3 camPos=mul(unity_WorldToCamera,float4(wpos,1)).xyz;
                float d=(camPos.z-_ProjectionParams.y)/(_ProjectionParams.z - _ProjectionParams.y);
                d=d/_ProjectionParams.w;
                return d;
            }
            fixed4 frag(v2f i):SV_Target
            {
                //return 1;
                float3 wpos=float3(i.tangentToWorld[0].w,i.tangentToWorld[1].w,i.tangentToWorld[2].w);
                fixed3 viewDir=normalize(_WorldSpaceCameraPos-wpos);
                float2 speed=_Time.y*_WaveSpeed.zw;
                //float3 bump=normalize(i.tangentToWorld[2].xyz);
                float3 bump=(tex2D(_NormCS,i.uv.zw )).xyz;
                //return fixed4(bump,1);
                float3 biT=normalize(i.tangentToWorld[1].xyz);
                //float3 bump=getBump(float4(i.uv.zw,0,0),speed);
                // float3 bump2=UnpackNormal(tex2D(_WaveMap,(i.uv.zw-speed))).rgb;
                // float3 bump=normalize(bump1+bump2);
                float2 ofs=(bump.xy)*_WaveSpeed.x;
                //return fixed4(bump,1);
                float2 offset=ofs*_Distortion;
                float2 refrOfs=ofs*_RefractionDistortion;
                float4 originPos=i.screenPos;
                i.screenPos.xy+=offset;
                float4 duv=originPos;
                duv.xy+=refrOfs;
                float depth=Linear01Depth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD(duv))));
                bump=lerp(bump,_AlignmentNormal,depth*_JitterDepthScale);
                float planedepth=WorldPostionToLinearDepth(wpos);
                float rd=Linear01Depth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(originPos))));
                float relDepth=(depth-planedepth);
                float4 grpos=originPos;
                //smoothstep(0.001,0.1,relDepth);
                //return relDepth;
                //float pc=smoothstep(0,0.3,relDepth);
                float2 Ofs=refrOfs;//*pc;
                float flag=step(-0.01,relDepth);
                grpos.xy+=flag*Ofs;
                //return flag;               
                relDepth=rd-planedepth;
                //return depth;
                fixed3 refrCol=tex2Dproj(_RefractionTex,grpos).rgb;
                relDepth=smoothstep(0.001,0.5,relDepth);
                float rD=relDepth;
                float boardDepth=smoothstep(1-0.00000003,1,1-relDepth);
                relDepth=depth-planedepth;
                relDepth=smoothstep(0.001,0.5,relDepth);
                relDepth*=flag;
                relDepth+=(1-flag)*rD;
                //relDepth+=(1 - flag);
                //return relDepth;
                _BoardColor=tex2D(_BoardTex,half2((wpos.z+wpos.x)/2,boardDepth));
                relDepth=pow(relDepth,_RefractionAlpha);
                relDepth=saturate(relDepth);
                refrCol=lerp(refrCol,_Color,relDepth);
                //relDepth=smoothstep(-0.01,-0.001,relDeptuh);
                //return step(-0.01,relDepth);
                fixed3 reflCol=tex2Dproj(_MainTex,UNITY_PROJ_COORD(i.screenPos)).rgb;

                //bump=i.tangentToWorld[2].xyz;
                bump=normalize(float3(i.tangentToWorld[0].xyz*bump.x+i.tangentToWorld[1].xyz*bump.y+i.tangentToWorld[2].xyz*bump.z));
                
                
                #if defined(SHADOWS_SCREEN) && defined(_RECSHADOW)
                UNITY_LIGHT_ATTENUATION(atten,i,wpos);
                #else
                float atten=1;
                #endif
                //atten=1;
                
                atten=lerp((1-_ShadowIntensity),1,atten);
                half3 T=normalize(cross(i.tangentToWorld[1].xyz,bump));
                //half nv=sqrt(1-dot(viewDir,T)*dot(viewDir,T));
                half3 l=_AlignmentLight.xyz;
                //half3 l=_WorldSpaceLightPos0.xyz;
                half nv=saturate(dot(viewDir,_AlignmentNormal.xyz));
                //half nl=sqrt(dot(l,T)*dot(l,T));
                half nl=saturate(dot(l,bump));
                half df=saturate(nl)*atten;
                half3 h=normalize(viewDir+l);
                //half TH=dot(T,h);
                //half nH=sqrt(1-TH*TH)*atten;
                half nH=saturate(dot(bump,h));
                df=saturate(pow(df,_LightReflectionScale));
                fixed fresnel=pow((1-nv),4);
                // float hDotN=saturate(dot(h,bump));
                // hDotN=pow(hDotN,_LightSepcularScale);
                //_ReflectColor=lerp(_LightReflectionBackColor,_LightReflectionColor,df);
                reflCol=lerp(reflCol,_ReflectColor,fresnel*_FresnelMax);
                //reflCol=lerp(_ReflectColor,reflCol,fresnel);
                #if defined (_RECSHADOW)
                fixed3 finalColor=fresnel*reflCol+(1-fresnel)*refrCol;
                #else
                fixed3 finalColor=fresnel*reflCol+(1-fresnel)*refrCol;
                #endif
                fixed3 c= lerp(_LightReflectionBackColor,_LightReflectionColor,df);
                finalColor=lerp(finalColor, c,_ColorAlpha);   
                finalColor+=pow(nH,_LightSepcularScale*_LightSepcularScale*_LightSepcularScale)*_SpecColor;
                //finalColor=lerp(finalColor,_BoardColor,boardDepth);
                return df;
            }
            ENDCG
        }
    }
    FallBack "VertexLit"
    CustomEditor "SimpleWaterGUI"
}