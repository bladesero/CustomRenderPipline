#define TEMPLATE_2_FLT(FunctionName, Parameter1, Parameter2, FunctionBody) \
    float  FunctionName(float  Parameter1, float  Parameter2) { FunctionBody; } \
    float2 FunctionName(float2 Parameter1, float2 Parameter2) { FunctionBody; } \
    float3 FunctionName(float3 Parameter1, float3 Parameter2) { FunctionBody; } \
    float4 FunctionName(float4 Parameter1, float4 Parameter2) { FunctionBody; }

#define TEMPLATE_3_FLT(FunctionName, Parameter1, Parameter2, Parameter3, FunctionBody) \
    float  FunctionName(float  Parameter1, float  Parameter2,float Parameter3) { FunctionBody; } \
    float2 FunctionName(float2 Parameter1, float2 Parameter2,float2 Parameter3) { FunctionBody; } \
    float3 FunctionName(float3 Parameter1, float3 Parameter2,float3 Parameter3) { FunctionBody; } \
    float4 FunctionName(float4 Parameter1, float4 Parameter2,float4 Parameter3) { FunctionBody; }

TEMPLATE_2_FLT(PositivePow, base, power, return pow(abs(base), power))

TEMPLATE_3_FLT(Min3, a, b, c, return min(min(a, b), c))

TEMPLATE_3_FLT(Max3, a, b, c, return max(max(a, b), c))

#define SLICE_ARRAY_INDEX       0
#define TEXTURE2D(textureName)                Texture2D textureName
#define TEXTURE2D_ARRAY(textureName)          Texture2DArray textureName
#define TEXTURE2D_X                 TEXTURE2D_ARRAY
#define LOAD_TEXTURE2D(textureName, unCoord2)                                   textureName.Load(int3(unCoord2, 0))
#define SAMPLE_TEXTURE2D_ARRAY(textureName, samplerName, coord2, index)                  textureName.Sample(samplerName, float3(coord2, index))
#define SAMPLE_TEXTURE2D(textureName, samplerName, coord2)              textureName.Sample(samplerName, coord2)
#define SAMPLE_DEPTH_TEXTURE(textureName, samplerName, coord2)          SAMPLE_TEXTURE2D(textureName, samplerName, coord2).r
#define SAMPLE_TEXTURE2D_ARRAY_LOD(textureName, samplerName, coord2, index, lod)         textureName.SampleLevel(samplerName, float3(coord2, index), lod)
#define SAMPLE_TEXTURE2D_X(textureName, samplerName, coord2)            SAMPLE_TEXTURE2D_ARRAY(textureName, samplerName, coord2, SLICE_ARRAY_INDEX)
#define SAMPLE_TEXTURE2D_X_LOD(textureName, samplerName, coord2, lod)   SAMPLE_TEXTURE2D_ARRAY_LOD(textureName, samplerName, coord2, SLICE_ARRAY_INDEX, lod)
#define SAMPLER(samplerName)                  SamplerState samplerName



//Function
float Luminance(float3 linearRgb)
{
    return dot(linearRgb, float3(0.2126729, 0.7151522, 0.0721750));
}