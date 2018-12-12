#include "UnityCG.cginc"
#pragma exclude_renderers d3d11
float _TessellationScale;
#define DS_PROGRAM_INTERPOLATE(fieldName) data.fieldName=\
    patch[0].fieldName * barycentricCoordinates.x + \
    patch[1].fieldName * barycentricCoordinates.y + \
    patch[2].fieldName * barycentricCoordinates.z;


struct TVD
{
    float4 vertex:INTERNALTESSPOS;
	float3 normal:NORMAL;
	float4 tangent:TANGENT;
	float2 uv:TEXCOORD0;
	float2 uv1:TEXCOORD1;
	float2 uv2:TEXCOORD2;
};
struct appdata_tess
{
    float4 vertex:POSITION;
    float3 normal:NORMAL;
	float4 tangent:TANGENT;
	float2 uv:TEXCOORD0;
	float2 uv1:TEXCOORD1;
	float2 uv2:TEXCOORD2;
};
struct TessellationFactors
{
    float edge[3] :SV_TessFactor;
    float inside:SV_InsideTessFactor;
};

TVD vert(appdata_tess v)
{
    TVD p;
    p.vertex = v.vertex;
	p.normal = v.normal;
	p.tangent = v.tangent;
	p.uv = v.uv;
	p.uv1 = v.uv1;
	p.uv2 = v.uv2;
    return p;
}

inline float TessellationEdgeFactor(TVD tv1,TVD tv2)
{
    float3 p0=UnityObjectToViewPos(tv1.vertex);
    float3 p1=UnityObjectToViewPos(tv2.vertex);
    float edgeLength=distance(p0,p1);
    float3 center=(p0+p1)*0.5;
    //float viewDistance=distance(center,_WorldSpaceCameraPos);
    float viewDistance=length(center);
    return (_TessellationScale*1000000)/(viewDistance*viewDistance*viewDistance);
}

inline TessellationFactors hsCountFunc(InputPatch<TVD,3> patch)
{
    TessellationFactors f;
    // f.edge[0]=1;
    // f.edge[1]=1;
    // f.edge[2]=1;
    // f.inside=1;
    f.edge[0]=TessellationEdgeFactor(patch[1],patch[2]);
    f.edge[1]=TessellationEdgeFactor(patch[0],patch[2]);
    f.edge[2]=TessellationEdgeFactor(patch[0],patch[1]);
    f.inside=(f.edge[0] + f.edge[1] + f.edge[2]) * (1 / 3.0);
    return f;
}
[UNITY_domain("tri")]
[UNITY_partitioning("fractional_odd")]
[UNITY_outputtopology("triangle_cw")]
[UNITY_patchconstantfunc("hsCountFunc")]
[UNITY_outputcontrolpoints(3)]
inline TVD hs(InputPatch<TVD,3> patch,uint id:SV_OutputControlPointID)
{
    return patch[id];
}
// [UNITY_domain("tri")]
// v2f ds(TessellationFactors factors,
//         OutputPatch<TVD,3> patch,
//         float3 barycentricCoordinates:SV_DomainLocation)
// {
//     TVD data;
//     DS_PROGRAM_INTERPOLATE(vertex);
//     DS_PROGRAM_INTERPOLATE(tangent);
//     DS_PROGRAM_INTERPOLATE(texcoord);
//     DS_PROGRAM_INTERPOLATE(normal);
//     return TessellationVertex(data);
// }
