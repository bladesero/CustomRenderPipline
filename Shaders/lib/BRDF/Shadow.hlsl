struct DirectionalShadowData
{
    float strength;
    int tileIndex;
    float normalBias;
    int shadowMaskChannel;
};

struct Light
{
    float3 color;
    float3 direction;
    float attenuation;
};

float4x4 _dirShadowMatrix;
Texture2D _dirShadowArray;
#define SHADOW_SAMPLER sampler_linear_clamp_compare
#define SAMPLER_CMP(samplerName)              SamplerComparisonState samplerName
SAMPLER_CMP(SHADOW_SAMPLER);

#define SAMPLE_TEXTURE2D_SHADOW(textureName, samplerName, coord3)                    textureName.SampleCmpLevelZero(samplerName, (coord3).xy, (coord3).z)

float SampleDirectionalShadowAtlas(float3 positionSTS)
{
    return SAMPLE_TEXTURE2D_SHADOW(
		_dirShadowArray, SHADOW_SAMPLER, positionSTS);
}


float GetDirectionalShadowAttenuation(float3 normalWS, float3 positionWS)
{
    float3 normalBias = 0.025 * normalWS;
    float4 shadowSTS = mul(_dirShadowMatrix,
    float4(positionWS + normalBias, 1.0));
    float3 positionSTS = shadowSTS.xyz / shadowSTS.w;
    return SampleDirectionalShadowAtlas(positionSTS);
}