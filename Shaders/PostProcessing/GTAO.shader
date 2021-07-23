Shader "Hidden/PostProcess/GTAO"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            Name "Occlusion"
            HLSLPROGRAM

            float4x4 unity_MatrixVP;
            float2 _InterleavePatternScale;
            #include "../PostProcessing/GTAO.hlsl"

            #pragma vertex vert
            #pragma fragment frag_Occlusion
            //#pragma multi_compile SAMPLES_2 SAMPLES_4 SAMPLES_6 SAMPLES_8

#pragma multi_compile SAMPLES_8
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

            v2f_ao vert (appdata v)
            {
                v2f_ao o;
                o.pos = mul(unity_MatrixVP, v.vertex);
                o.uv = v.uv;
                o.uvr= v.uv* _InterleavePatternScale;
                return o;
            }

            sampler2D _MainTex;


            ENDHLSL
        }
    }
}
