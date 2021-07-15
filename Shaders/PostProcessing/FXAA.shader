Shader "Hidden/PostProcess/FXAA"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
        SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            Name "FXAA"
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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP,v.vertex);
                o.uv = v.uv;
                return o;
            }

            TEXTURE2D(_MainTex);
            float4 _MainTex_TexelSize;

            float3 Fetch(float2 coords, float2 offset)
            {
                float2 uv = coords + offset;
                return SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, uv).xyz;
            }

            half3 Load(int2 icoords, int idx, int idy)
            {
                return LOAD_TEXTURE2D(_MainTex, clamp(icoords + int2(idx, idy), 0, _MainTex_TexelSize.zw - 1.0)).xyz;
            }

            float4 frag(v2f i) : SV_Target
            {
                int2   positionSS = i.uv * _MainTex_TexelSize.zw;

                half3 color = Load(positionSS, 0, 0).xyz;

                half3 rgbNW = Load(positionSS, -1, -1);
                half3 rgbNE = Load(positionSS, 1, -1);
                half3 rgbSW = Load(positionSS, -1, 1);
                half3 rgbSE = Load(positionSS, 1, 1);

                rgbNW = saturate(rgbNW);
                rgbNE = saturate(rgbNE);
                rgbSW = saturate(rgbSW);
                rgbSE = saturate(rgbSE);
                color = saturate(color);

                half lumaNW = Luminance(rgbNW);
                half lumaNE = Luminance(rgbNE);
                half lumaSW = Luminance(rgbSW);
                half lumaSE = Luminance(rgbSE);
                half lumaM = Luminance(color);

                float2 dir;
                dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
                dir.y = ((lumaNW + lumaSW) - (lumaNE + lumaSE));

                half lumaSum = lumaNW + lumaNE + lumaSW + lumaSE;
                float dirReduce = max(lumaSum * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
                float rcpDirMin = rcp(min(abs(dir.x), abs(dir.y)) + dirReduce);

                dir = min((FXAA_SPAN_MAX).xx, max((-FXAA_SPAN_MAX).xx, dir * rcpDirMin)) * _MainTex_TexelSize.xy;

                half3 rgb03 = Fetch(i.uv, dir * (0.0 / 3.0 - 0.5));
                half3 rgb13 = Fetch(i.uv, dir * (1.0 / 3.0 - 0.5));
                half3 rgb23 = Fetch(i.uv, dir * (2.0 / 3.0 - 0.5));
                half3 rgb33 = Fetch(i.uv, dir * (3.0 / 3.0 - 0.5));

                rgb03 = saturate(rgb03);
                rgb13 = saturate(rgb13);
                rgb23 = saturate(rgb23);
                rgb33 = saturate(rgb33);

                half3 rgbA = 0.5 * (rgb13 + rgb23);
                half3 rgbB = rgbA * 0.5 + 0.25 * (rgb03 + rgb33);

                half lumaB = Luminance(rgbB);

                half lumaMin = Min3(lumaM, lumaNW, Min3(lumaNE, lumaSW, lumaSE));
                half lumaMax = Max3(lumaM, lumaNW, Max3(lumaNE, lumaSW, lumaSE));

                color = ((lumaB < lumaMin) || (lumaB > lumaMax)) ? rgbA : rgbB;

                //color = 1-SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, i.uv).xyz;

                return float4(color,1.0);
            }
            ENDHLSL
        }
    }
}
