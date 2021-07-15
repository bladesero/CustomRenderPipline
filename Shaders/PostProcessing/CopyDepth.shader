Shader "Hidden/PostProcess/CopyDepth"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite On ZTest Always

        Pass
        {
            Name "CopyDepth"
            HLSLPROGRAM

            float4x4 unity_MatrixVP;

#define FXAA_SPAN_MAX           (8.0)
#define FXAA_REDUCE_MUL         (1.0 / 8.0)
#define FXAA_REDUCE_MIN         (1.0 / 128.0)

            #pragma vertex vert
            #pragma fragment frag

#include "../lib/Common/Common.hlsl"
            SAMPLER(sampler_LinearClamp);

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP,v.vertex);
                o.uv = v.uv;
                return o;
            }

            TEXTURE2D(_MainTex);
            float4 _MainTex_TexelSize;

            float frag (v2f i) : SV_DEPTH
            {
                return SAMPLE_DEPTH_TEXTURE(_MainTex,sampler_LinearClamp,i.uv);
            }
            ENDHLSL
        }
    }
}
