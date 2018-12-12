#define PI 3.141592653
#define SEA_HEIGHT 0.6
#define SEA_FREQ 0.16
#define SEA_CHOPPY 4.0
#define ITER_GEOMETRY 5
#define SEA_SPEED 0.8
#define SEA_TIME (1.0+_Time.y*SEA_SPEED)
float _FresnelPow,_SpecPow,_DiffPow,_RelativeHeightMin,_DistFactor,_WaterAlpha,SEA_LIGHT_ATTEN,_SpecAtten,_SpecFact;
float4 _SeaBase,_SeaWaterColor;
samplerCUBE _SkyBox;
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
float diffuse(float3 n,float3 l,float p)
{
    return pow(dot(n,l)*0.4+0.6,p);
}
float specular(float3 n,float3 l,float3 e,float s)
{
    float nrm=(s+_SpecAtten)/(PI*_SpecFact);
    return pow(max(dot(reflect(e,n),l),0.0),s)*nrm;
}
fixed3 SkyColor(float3 e,fixed3 reflC,float fresnel)
{
    //e=normalize(e);
    e.y=max(e.y,0.0);
    fixed3 env=texCUBE(_SkyBox,e).rgb;
    env=lerp(env,reflC,fresnel);
    return env;
}
fixed3 SkyColorNoReflC(float3 e)
{
    e.y=saturate(e.y);
    return float3(clamp(1.0-e.y,0,0.9),clamp(1.0-e.y,0,0.9),0.7+(1.0-e.y)*0.4);
}
fixed3 SeaColorNoRef(float3 p,float3 n,float3 l,float3 eye,float3 ofs,float a)
{
    float fresnel = clamp(1.0 - dot(n,eye), 0.0, 1.0);
    fresnel = pow(fresnel,3.0) * 0.65;
    fixed3 reflected=SkyColorNoReflC(reflect(-eye,n));
    fixed3 refract=_SeaBase+diffuse(n,l,_DiffPow)*_SeaWaterColor*0.15;
    fixed3 color=lerp(refract,reflected,fresnel);
    float lumiance=Luminance(color);
    lumiance=smoothstep(0,0.3,lumiance);
    //a=lerp(a,1,lumiance);
    float atten=max(1.0-dot(ofs,ofs)*_DistFactor,0);
    color+=_SeaWaterColor*(p.y-_RelativeHeightMin)*0.18*atten;
    color+=specular(n,l,-eye,_SpecPow);
    return color*a;
}
fixed3 SeaColorNoSpec(float3 p,float3 n,float3 l,float3 eye,float3 ofs,fixed3 reflC,fixed3 refrC,float relDepth,float a)
{
    float fresnel = clamp(1.0 - dot(n,eye), 0.0, 1.0);
    fresnel = pow(fresnel,3.0) * 0.65;
    fixed3 reflected=SkyColor(reflect(-eye,n),reflC,fresnel);
    fixed3 refract=_SeaBase+diffuse(n,l,_DiffPow)*_SeaWaterColor*0.15;
    #if defined(_REFRACTION)
    refract=lerp(refrC,refract,saturate(relDepth*_WaterAlpha));
    #endif
    fixed3 color=lerp(refract,reflected,fresnel);
    float lumiance=Luminance(color);
    lumiance=smoothstep(0,0.5,lumiance);
    a=lerp(a,1,lumiance);
    float atten=max(1.0-dot(ofs,ofs)*_DistFactor,0);
    color+=_SeaWaterColor*(p.y-_RelativeHeightMin)*0.18*atten;
    return color*a;
}
fixed3 SeaColor(float3 p,float3 n,float3 l,float3 eye,float3 ofs,fixed3 reflC,fixed3 refrC,float relDepth,float a)
{
    float fresnel = clamp(1.0 - dot(n,eye), 0.0, 1.0);
    fresnel = pow(fresnel,_FresnelPow) * 0.65;
    fixed3 reflected=SkyColor(reflect(-eye,n),reflC,0.6);
    fixed3 refract=_SeaBase+diffuse(n,l,80)*_SeaWaterColor*0.12;
    #if defined(_REFRACTION)
    refract=lerp(refrC,refract,saturate(relDepth*_WaterAlpha));
    #endif
    fixed3 color=lerp(refract,reflected,fresnel);
    float lumiance=Luminance(color);
    lumiance=smoothstep(0,0.5,lumiance);
    a=lerp(a,1,lumiance);
    float atten=max(1.0-dot(ofs,ofs)*_DistFactor,0);
    float relativeDst=(p.y-_RelativeHeightMin);
    color+=(_SeaWaterColor*relativeDst*SEA_LIGHT_ATTEN*atten);
    //color=lerp(color,reflC,fresnel);
    color+=specular(n,l,-eye,_SpecPow);
    return color*a;

}