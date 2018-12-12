Shader "ArtStandard/Environment/Shadow/Projector"
{
    SubShader
    {

        Pass
        {
            NAME "ForwardShadowRec"
            Tags{"LightMode"="ForwardBase" "Queue"="Overlay" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            sampler2D _ShadowMap;
            float4x4 unity_Projector;
            float4x4 unity_ProjectorClip;
            struct v2f
            {
                float4 pos:SV_POSITION;
                float4 uv:TEXCOORD0;
                float4 fuv:TEXCOORD1;
            };
            v2f vert(float4 vertex:POSITION)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(vertex);
                o.uv=mul(unity_Projector,vertex);
                o.fuv=mul(unity_ProjectorClip,vertex);
                return o;
            }
            fixed4 frag(v2f i):SV_Target
            {
                fixed4 tex=tex2Dproj(_ShadowMap,i.uv);
                return tex;
            }
            ENDCG
        }
    }
}