Shader "CRP/Lit"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        _NormalMap("Normal", 2D) = "bump" {}
        _MetallicMap("Metal", 2D) = "white" {}
        _RoughnessMap("Rough", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "Pipeline" }
        LOD 200

        Pass
        {
            Name "CRPLit"
            Tags{"LightMode" = "CRPLit"}
        HLSLPROGRAM
        #include "lib/BRDF/BRDF.hlsl"
        #include "lib/BRDF/Shadow.hlsl"
        //CBUFFER_START(UnityPerDraw)
        float4x4 unity_MatrixVP;
        float4x4 unity_ObjectToWorld;
        float4x4 unity_WorldToObject;
        float4x4 UNITY_MATRIX_M;
        float4x4 unity_MatrixInvV;
        float3 _WorldSpaceCameraPos;
        static float4x4 unity_MatrixITMV = transpose(mul(unity_WorldToObject, unity_MatrixInvV));
        float4x4 UNITY_MATRIX_MV;

        //CBUFFER_END
        float4 _Color;
        Texture2D _MainTex;
        SamplerState sampler_MainTex;
        Texture2D _NormalMap;
        SamplerState sampler_NormalMap;
        Texture2D _MetallicMap;
        SamplerState sampler_MetallicMap;
        Texture2D _RoughnessMap;
        SamplerState sampler_RoughnessMap;
        float _Glossiness;
        float _Metallic;

#pragma target 3.5
#pragma multi_compile_instancing

#pragma vertex vert
#pragma fragment frag

        struct vertexInput
    {
        float4 pos:POSITION;
        float3 normal:NORMAL;
        float2 uv:TEXCOORD0;
        float4 tangent:TANGENT;
};
    struct vertexOutput
    {
        float4 clipPos : SV_POSITION;
        float2 uv : TEXCOORD0;
        float3 vnormal:TEXCOORD1;
        float3 normal : VAR_NORMAL;
        float4 tangentWS:VAR_TANGENT;
        float4 worldPos : TEXCOORD2;
        };

    float3 GetNormalTS(float2 uv)
    {
        float4 map = _NormalMap.Sample(sampler_NormalMap, uv);
        float3 normal = UnpackNormalRGB(map, 1);
        return normal;
    }

    vertexOutput vert(vertexInput input)
    {
        vertexOutput output;
        float4 worldPos = mul(unity_ObjectToWorld, input.pos);
        output.clipPos = mul(unity_MatrixVP, worldPos);
        output.worldPos = worldPos;
        output.normal = mul((float3x3)unity_ObjectToWorld,input.normal);
        output.vnormal = normalize(mul((float3x3)unity_MatrixITMV, input.normal));
        //output.normal = input.normal;
        output.uv = input.uv;
        output.tangentWS = float4(mul((float3x3)unity_ObjectToWorld,input.tangent.xyz), input.tangent.w);
        return output;
    }

    float4 frag(vertexOutput input, out float3 GRT0:SV_Target1, out float3 GRT1 : SV_Target2) :SV_TARGET
    {
        //base vectors
        float3 viewdir = normalize(_WorldSpaceCameraPos.xyz - input.worldPos.xyz);
        float3 lightdir = normalize(_MainLightPosition.xyz);
        float3 normal = normalize(input.normal);
        float3 normalTS = normalize(GetNormalTS(input.uv));
        //float3 normalTS = _NormalMap.Sample(sampler_NormalMap, input.uv).rgb;

        normal = NormalTangentToWorld(normalTS, normal, normalize(input.tangentWS));
        float3 reflectdir = reflect(-viewdir, normal);

        float ndotl = saturate(dot(normal, lightdir));
        float3 color = ndotl;

        float4 albedo = _MainTex.Sample(sampler_MainTex, input.uv);
        float metal= _MetallicMap.Sample(sampler_MetallicMap, input.uv).r;
        float rough= _RoughnessMap.Sample(sampler_RoughnessMap, input.uv).r;


        color *= albedo.rgb;
        float3 specular = BlinnPhongBRDF(viewdir, lightdir, normal, (1-_Glossiness)* (1 - _Glossiness));
        float3 GGX = GGXBRDF(viewdir, lightdir, normal, _Glossiness);
        float3 sh = SampleSH(normal);
        float3 enviromentReflect = EnviromentReflection(reflectdir, 1 - _Glossiness);

        InputData inputData;
        inputData.positionWS = input.worldPos.xyz;
        inputData.normalWS = normal;
        inputData.viewDirectionWS = viewdir;
        inputData.bakedGI = 1;
        
        //GRT0 = inputData.normalWS;
        GRT0 = input.vnormal;
        GRT1 = albedo.rgb;

        float lightAttenuation = GetDirectionalShadowAttenuation(inputData.normalWS, inputData.positionWS);
        float3 brdf = PBR(inputData, albedo.rgb, _Metallic* metal, float3(0.5, 0.5, 0.5), _Glossiness* rough, 1, float3(0, 0, 0), lightAttenuation);

        return float4(brdf,1);
        //return float4(normal,1);
    }

        ENDHLSL

        }

        Pass
        {
            Tags{"LightMode"="ShadowCaster"}

            ColorMask 0

            HLSLPROGRAM
#pragma target 3.5

#pragma vertex ShadowVertex
#pragma fragment ShaodwFragment

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;
            Texture2D _BaseMap;
            SamplerState sampler_BaseMap;
            float4 _BaseMap_TexelSize;

            struct vertexInput {
                float4 posOS : POSITION;
                float2 uv :TEXCOORD0;
            };

            struct vertexOutput {
                float4 posCS:SV_POSITION;
                float2 uv:VAR_BASE_UV;
            };

            vertexOutput ShadowVertex(vertexInput input) {
                vertexOutput output;
                float4 worldPos = mul(unity_ObjectToWorld, input.posOS);
                output.posCS = mul(unity_MatrixVP, worldPos);
                output.uv = input.uv * _BaseMap_TexelSize.xy + _BaseMap_TexelSize.zw;
                return output;
            }

            half4  ShaodwFragment(vertexOutput input):SV_TARGET {
                return 1;
            }

            ENDHLSL
        }
    }
        //FallBack "Diffuse"
}
