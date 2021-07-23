//GTAO lib
#include "../lib/Common/Common.hlsl"

float4 _Params;
float4 unity_OrthoParams;
float4 _ZBufferParams;
float4 _ProjectionParams;
float4x4 UNITY_MATRIX_IT_MV;
float3 _FarCorner;
#define COMPUTE_VIEW_NORMAL normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal))
inline float LinearEyeDepth(float z)
{
    return 1.0 / (_ZBufferParams.z * z + _ZBufferParams.w);
}

TEXTURE2D(_CameraNormalTexture);
SAMPLER(sampler_CameraNormalTexture);
TEXTURE2D(_CameraColorTexture);
SAMPLER(sampler_CameraColorTexture);
TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);

float4 _CameraNormalTexture_TexelSize;

TEXTURE2D(_AxisTexture);
SAMPLER(sampler_AxisTexture);

inline void samplePositionAndNormal(float2 uv, out float3 p, out float3 n)
{
    float depth;
    if (unity_OrthoParams.w<0.5)
    {
        depth = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uv).x);
    }else
    {
        depth = _ProjectionParams.y + (_ProjectionParams.z - _ProjectionParams.y) * SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uv).x;
    }
    n = SAMPLE_TEXTURE2D(_CameraNormalTexture, sampler_CameraNormalTexture, uv).xyz;

    float3 ray = (float3(-0.5, -0.5, 0) + float3(uv, -1)) * _FarCorner;
    p = ray * depth / _FarCorner.z;
}

float calculateAO(float3 fragP,float3 fragN,float3 sampleP)
{
    float3 v = sampleP - fragP;
    float vvDot = dot(v, v);
    float oneOverSqrt = rsqrt(vvDot);
    float fvDot = dot(fragN, v) * oneOverSqrt;
    
    float falloff = saturate(1.0 - _Params.w*vvDot);
    float ao = max(-_Params.z, fvDot - _Params.y);
    
    return ao;
}

struct v2f_ao
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float2 uvr : TEXCOORD1;
};

float3 frag_Occlusion(v2f_ao i) : SV_Target
{
    float ao = float(0);
    
    float3 PosVS, PosSample;
    float3 NormalVS, NormalSample;
    samplePositionAndNormal(i.uv, PosVS, NormalVS);
    
    float radius;
    if (unity_OrthoParams.w < 0.5)
    {
        radius = clamp(_Params.x / -PosVS.z, 0.02, 0.3);
    }
    else
    {
        radius = clamp(_Params.x / _FarCorner.y, 0.02, 0.3);
    }
    half2 aspect_ratio = half2(_CameraNormalTexture_TexelSize.w / _CameraNormalTexture_TexelSize.z, 1);
    
    float3 pattern = SAMPLE_TEXTURE2D(_AxisTexture, sampler_AxisTexture, i.uvr).xyz;
    float2 axis1 = pattern.xy * radius;
    
    #if defined(SAMPLES_8)
	axis1 /= 8;
	#elif defined(SAMPLES_6)
 	axis1 /= 6;
	#elif defined(SAMPLES_4)
	axis1 /= 4;
	#elif defined(SAMPLES_2)
 	axis1 /= 2;
	#endif
    
    float2 axis2 = half2(-axis1.y, axis1.x);
    
    //Axis 1 negative samples:
#if defined(SAMPLES_8)
		for (int s = 1; s <= 8; ++s)
#elif defined(SAMPLES_6)
		for (int s = 1; s <= 6; ++s)
#elif defined(SAMPLES_4)
		for (int s = 1; s <= 4; ++s)
#elif defined(SAMPLES_2)
		for (int s = 1; s <= 2; ++s)
#else 
    for (int s = 1; s <= 1; ++s)
		#endif
    {
        float2 uv = float2(i.uv - axis1.xy * (s - pattern.z) * aspect_ratio);
        samplePositionAndNormal(uv, PosSample, NormalSample);
        ao += calculateAO(PosVS, NormalVS, PosSample);
    }
    
    //Axis 1 positive samples:
#if defined(SAMPLES_8)
		for (int s = 1; s <= 8; ++s)
#elif defined(SAMPLES_6)
		for (int s = 1; s <= 6; ++s)
#elif defined(SAMPLES_4)
		for (int s = 1; s <= 4; ++s)
#elif defined(SAMPLES_2)
		for (int s = 1; s <= 2; ++s)
#else 
    for (int s = 1; s <= 1; ++s)
#endif
    {
        float2 uv = float2(i.uv + axis1.xy * (s - pattern.z) * aspect_ratio);
        samplePositionAndNormal(uv, PosSample, NormalSample);
        ao += calculateAO(PosVS, NormalVS, PosSample);
    }
    
     //Axis 2 negative samples:
#if defined(SAMPLES_8)
		for (int s = 1; s <= 8; ++s)
#elif defined(SAMPLES_6)
		for (int s = 1; s <= 6; ++s)
#elif defined(SAMPLES_4)
		for (int s = 1; s <= 4; ++s)
#elif defined(SAMPLES_2)
		for (int s = 1; s <= 2; ++s)
#else 
    for (int s = 1; s <= 1; ++s)
#endif
    {
        float2 uv = float2(i.uv - axis2.xy * (s - pattern.z) * aspect_ratio);
        samplePositionAndNormal(uv, PosSample, NormalSample);
        ao += calculateAO(PosVS, NormalVS, PosSample);
    }
    
      //Axis 2 positive samples:
#if defined(SAMPLES_8)
		for (int s = 1; s <= 8; ++s)
#elif defined(SAMPLES_6)
		for (int s = 1; s <= 6; ++s)
#elif defined(SAMPLES_4)
		for (int s = 1; s <= 4; ++s)
#elif defined(SAMPLES_2)
		for (int s = 1; s <= 2; ++s)
#else 
    for (int s = 1; s <= 1; ++s)
#endif
    {
        float2 uv = float2(i.uv + axis2.xy * (s - pattern.z) * aspect_ratio);
        samplePositionAndNormal(uv, PosSample, NormalSample);
        ao += calculateAO(PosVS, NormalVS, PosSample);
    }
    
#if defined(SAMPLES_8)
	ao /= 32;
#elif defined(SAMPLES_6)
	ao /= 24;
#elif defined(SAMPLES_4)
	ao /= 16;
#elif defined(SAMPLES_2)
	ao /= 8;
#else 
    ao /= 4;
#endif
    
    //float2 uv = float2(i.uv + axis2.xy * (s - pattern.z));
    //samplePositionAndNormal(uv, PosSample, NormalSample);
    //ao = calculateAO(PosVS, NormalVS, PosSample);
    //float3 v = (PosSample - PosVS);
    //float vvDot = dot(v, v);
    //float oneOverSqrt = rsqrt(vvDot);
    //float fvDot = dot(NormalVS, v) * oneOverSqrt;
    //float falloff = saturate(1.0 - _Params.w * vvDot);
    //float ao2 = max(-_Params.z, fvDot - _Params.y);
    ao = PositivePow(1 - ao, 1.5);
    return ao;
}