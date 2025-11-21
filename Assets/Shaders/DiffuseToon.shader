Shader "Custom/DiffuseToon"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _SpecColor("Specular Color", Color) = (1,1,1,1)
        _Shininess("Shininess", Range(0.1, 100)) = 16
        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimPower ("Rim Power", Range(0.1, 8.0)) = 1.5
        _InvertColor ("Invert Colors", Range(0, 1)) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float4 _SpecColor;
                float _Shininess;
                float4 _RimColor;
                float _RimPower;
                float _InvertColor;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                
                float3 worldPosWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDirWS = normalize(GetWorldSpaceViewDir(IN.positionOS.xyz));

                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;

                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);

                half3 normalWS = normalize(IN.normalWS);
                half NdotL = saturate(dot(normalWS, lightDir));
                half3 ambientSH = SampleSH(normalWS);
                half3 diffuse = color.rgb * NdotL;
                half3 reflectDir = reflect(-lightDir, normalWS);

                half3 viewDir = normalize(IN.viewDirWS);
                half specFactor = pow(saturate(dot(reflectDir, viewDir)), _Shininess);
                half3 specular = _SpecColor.rgb * specFactor;

                half3 finalColor = diffuse + ambientSH * color.rgb + specular;

                half rimDot = 1.0 - saturate(dot(IN.viewDirWS, IN.normalWS));
                half rimFactor = pow(rimDot, _RimPower);
                
                rimFactor = floor(rimFactor * 2);
                finalColor += _InvertColor < 0.5 ? _RimColor.rgb * rimFactor : -_RimColor.rgb * rimFactor;
                
                return half4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
}
