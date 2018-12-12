#include "UnityCG.cginc"
#include "UnityStandardCore.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

struct a2v
{
    float4 vertex:POSITION;
    float4 tangent:TANGENT;
    float4 texcoord:TEXCOORD0;
    float3 normal:NORMAL;
};
struct a2vBase
{
    float4 vertex   : POSITION;
    half3 normal    : NORMAL;
    float2 uv0      : TEXCOORD0;
    float2 uv1      : TEXCOORD1;
#if defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META)
    float2 uv2      : TEXCOORD2;
#endif
    half4 tangent   : TANGENT;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};
struct Input
{
    float4 pos:SV_POSITION;
    float4 uv:TEXCOORD0;
    float3 eyeVec:TEXCOORD1;
    float3 worldPos:TEXCOORD2;
    float4 tangentToWorld[3]:TEXCOORD3;
    SHADOW_COORDS(6)
};
struct InputBase
{
    UNITY_POSITION(pos);
    float4 uv                            : TEXCOORD0;
    float3 eyeVec                         : TEXCOORD1;
    float4 tangentToWorld[3] : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
    half4 ambientOrLightmapUV             : TEXCOORD5;
    SHADOW_COORDS(6)
};
inline half4 a2vGIForward(a2vBase v, float3 posWorld, half3 normalWorld)
{
    half4 ambientOrLightmapUV = 0;
    // Static lightmaps
    #ifdef LIGHTMAP_ON
        ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
        ambientOrLightmapUV.zw = 0;
    // Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
    #elif UNITY_SHOULD_SAMPLE_SH
        #ifdef VERTEXLIGHT_ON
            // Approximated illumination from non-important point lights
            ambientOrLightmapUV.rgb = Shade4PointLights (
                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                unity_4LightAtten0, posWorld, normalWorld);
        #endif

        ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, ambientOrLightmapUV.rgb);
    #endif

    #ifdef DYNAMICLIGHTMAP_ON
        ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
    #endif

    return ambientOrLightmapUV;
}


fixed4 MetallicPBRRender(float4 tex,float3 worldNormal,float3 worldPos,float3 eyeVec,float atten,float f)
{
    FragmentCommonData s=MetallicSetup(tex);
    float alpha=Alpha(tex.xy);
    clip(alpha-_Cutoff);
    s.normalWorld=worldNormal;
    s.eyeVec=eyeVec;
    s.posWorld=worldPos;
    s.diffColor=PreMultiplyAlpha(s.diffColor,alpha,s.oneMinusReflectivity,s.alpha);
    UnityLight mainLight=MainLight();

    s.smoothness=f;

    float4 ambientOrLightmapUV;
    ambientOrLightmapUV.rgb = Shade4PointLights (
    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
    unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
    unity_4LightAtten0, worldPos, worldNormal);

    half occlusion=Occlusion(tex.xy);
    UnityGI gi=FragmentGI(s,occlusion,ambientOrLightmapUV,atten,mainLight);
    float4 c=UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
    c.rgb+=Emission(tex.xy);
    c.a=alpha;
    return OutputForward(c,s.alpha);
}
fixed4 MetallicPBRRender(float4 tex,float3 worldNormal,float3 worldPos,float3 eyeVec,float atten)
{
    FragmentCommonData s=MetallicSetup(tex);
    float alpha=Alpha(tex.xy);
    clip(alpha-_Cutoff);
    s.normalWorld=worldNormal;
    s.eyeVec=eyeVec;
    s.posWorld=worldPos;
    s.diffColor=PreMultiplyAlpha(s.diffColor,alpha,s.oneMinusReflectivity,s.alpha);
    UnityLight mainLight=MainLight();

    float4 ambientOrLightmapUV;
    ambientOrLightmapUV.rgb = Shade4PointLights (
    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
    unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
    unity_4LightAtten0, worldPos, worldNormal);

    half occlusion=Occlusion(tex.xy);
    UnityGI gi=FragmentGI(s,occlusion,ambientOrLightmapUV,atten,mainLight);
    float4 c=UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
    c.rgb+=Emission(tex.xy);
    c.a=alpha;
    return OutputForward(c,s.alpha);
}
float3 PerPixelWN(float4 i_tex,float4 tangentToWorld[3])
{
    #ifdef _NORMALMAP
    half3 tangent = tangentToWorld[0].xyz;
    half3 binormal = tangentToWorld[1].xyz;
    half3 normal = tangentToWorld[2].xyz;

    #if UNITY_TANGENT_ORTHONORMALIZE
        normal = NormalizePerPixelNormal(normal);

        // ortho-normalize Tangent
        tangent = normalize (tangent - normal * dot(tangent, normal));

        // recalculate Binormal
        half3 newB = cross(normal, tangent);
        binormal = newB * sign (dot (newB, binormal));
    #endif

    half3 normalTangent = NormalInTangentSpace(i_tex);
    float3 normalWorld = NormalizePerPixelNormal(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well
    #else
    float3 normalWorld = normalize(tangentToWorld[2].xyz);
    #endif
    return normalWorld;  
}