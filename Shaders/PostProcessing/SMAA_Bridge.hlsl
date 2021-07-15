#ifndef UNIVERSAL_POSTPROCESSING_SMAA_BRIDGE
#define UNIVERSAL_POSTPROCESSING_SMAA_BRIDGE

#define SMAA_HLSL_4_1

#if _SMAA_PRESET_LOW
    #define SMAA_PRESET_LOW
#elif _SMAA_PRESET_MEDIUM
    #define SMAA_PRESET_MEDIUM
#else
    #define SMAA_PRESET_HIGH
#endif

#include "../lib/Common/Common.hlsl"

TEXTURE2D_ARRAY(_ColorTexture);
TEXTURE2D_ARRAY(_BlendTexture);
TEXTURE2D(_AreaTexture);
TEXTURE2D(_SearchTexture);

float4 _Metrics;

#define SMAA_RT_METRICS _Metrics
#define SMAA_AREATEX_SELECT(s) s.rg
#define SMAA_SEARCHTEX_SELECT(s) s.a
SAMPLER(sampler_LinearClamp);
SAMPLER(sampler_PointClamp);
#define LinearSampler sampler_LinearClamp
#define PointSampler sampler_PointClamp

#if UNITY_COLORSPACE_GAMMA
#define GAMMA_FOR_EDGE_DETECTION (1)
#else
#define GAMMA_FOR_EDGE_DETECTION (1/2.2)
#endif

#include "SMAA.hlsl"
// ----------------------------------------------------------------------------------------
// Edge Detection

float4x4 unity_MatrixVP;

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct VaryingsEdge
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 offsets[3] : TEXCOORD1;
};

VaryingsEdge VertEdge(appdata input)
{
    VaryingsEdge output;
    output.positionCS = mul(unity_MatrixVP, input.vertex);
    output.uv = input.uv;
    SMAAEdgeDetectionVS(output.uv, output.offsets);
    return output;
}

float4 FragEdge(VaryingsEdge input) : SV_Target
{
    return float4(SMAAColorEdgeDetectionPS(input.uv, input.offsets, _ColorTexture), 0.0, 0.0);
}

// ----------------------------------------------------------------------------------------
// Blend Weights Calculation

struct VaryingsBlend
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float2 pixcoord : TEXCOORD1;
    float4 offsets[3] : TEXCOORD2;
};

VaryingsBlend VertBlend(appdata input)
{
    VaryingsBlend output;
    output.positionCS = mul(unity_MatrixVP, input.vertex);
    output.uv = input.uv;
    SMAABlendingWeightCalculationVS(output.uv, output.pixcoord, output.offsets);
    return output;
}

float4 FragBlend(VaryingsBlend input) : SV_Target
{
    return SMAABlendingWeightCalculationPS(input.uv, input.pixcoord, input.offsets, _ColorTexture, _AreaTexture, _SearchTexture, 0);
}

// ----------------------------------------------------------------------------------------
// Neighborhood Blending

struct VaryingsNeighbor
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 offset : TEXCOORD1;
};

VaryingsNeighbor VertNeighbor(appdata input)
{
    VaryingsNeighbor output;
    output.positionCS = mul(unity_MatrixVP, input.vertex);
    output.uv = input.uv;
    SMAANeighborhoodBlendingVS(output.uv, output.offset);
    return output;
}

float4 FragNeighbor(VaryingsNeighbor input) : SV_Target
{
    return SMAANeighborhoodBlendingPS(input.uv, input.offset, _ColorTexture, _BlendTexture);
}

#endif // UNIVERSAL_POSTPROCESSING_SMAA_BRIDGE
