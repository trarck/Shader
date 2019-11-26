Shader "PBS/Standard"
{
    Properties
    {
		[Header(Base)]
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
	    _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0

		[Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}

		_BumpScale("Scale", Float) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}

		_Parallax("Height Scale", Range(0.005, 0.08)) = 0.02
		_ParallaxMap("Height Map", 2D) = "black" {}

		_OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		_OcclusionMap("Occlusion", 2D) = "white" {}

		_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}

		// Blending state
		[HideInInspector] _Mode("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
		[HideInInspector] _ZWrite("__zw", Float) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 300

        Pass
        {
			 Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			Blend[_SrcBlend][_DstBlend]
			ZWrite[_ZWrite]

			CGPROGRAM
			#pragma target 3.0

			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _PARALLAXMAP

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "Common.cginc"
			#include "UnityLightingCommon.cginc"
			#include "ShadingModels.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				half3  normal	 : NORMAL;
				float4 tangent	 : TANGENT;
            };

            struct v2f
            {
				float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
				float3 worldNormal:TEXCOORD1;
				float4 tangentToWorld[3] : TEXCOORD2;
            };

			half4       _Color;

			sampler2D   _MainTex;
			float4      _MainTex_ST;

			sampler2D   _BumpMap;
			half        _BumpScale;

			sampler2D   _SpecGlossMap;
			sampler2D   _MetallicGlossMap;
			half        _Metallic;
			float       _Glossiness;
			float       _GlossMapScale;

			sampler2D   _OcclusionMap;
			half        _OcclusionStrength;

			sampler2D   _ParallaxMap;
			half        _Parallax;

			half4       _EmissionColor;
			sampler2D   _EmissionMap;

			half3 UnpackScaleNormal(half4 packednormal, half bumpScale)
			{
				half3 normal = packednormal.xyz * 2 - 1;
				normal.xy *= bumpScale;
				return normal;
//#if defined(UNITY_NO_DXT5nm)
//				half3 normal = packednormal.xyz * 2 - 1;
//#if (SHADER_TARGET >= 30)
//				// SM2.0: instruction count limitation
//				// SM2.0: normal scaler is not supported
//				normal.xy *= bumpScale;
//#endif
//				return normal;
//#else
//				// This do the trick
//				packednormal.x *= packednormal.w;
//
//				half3 normal;
//				normal.xy = (packednormal.xy * 2 - 1);
//#if (SHADER_TARGET >= 30)
//				// SM2.0: instruction count limitation
//				// SM2.0: normal scaler is not supported
//				normal.xy *= bumpScale;
//#endif
//				normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
//				return normal;
//#endif
			}

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				//设置世界坐标
				o.tangentToWorld[0].w = posWorld.x;
				o.tangentToWorld[1].w = posWorld.y;
				o.tangentToWorld[2].w = posWorld.z;

				float3 normalWorld = UnityObjectToWorldNormal(v.normal);
				float3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				//设置转换矩阵
				float sign = v.tangent.w * unity_WorldTransformParams.w;
				float3 binormal = cross(normalWorld, tangentWorld) * sign;
				o.tangentToWorld[0].xyz = tangentWorld;
				o.tangentToWorld[1].xyz = binormal;
				o.tangentToWorld[2].xyz = normalWorld;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				half3 normalTangent = UnpackScaleNormal(tex2D(_BumpMap, i.uv), _BumpScale);
				half3 normalWorld = normalize(i.tangentToWorld[0].xyz * normalTangent.x + i.tangentToWorld[1] * normalTangent.y + i.tangentToWorld[2] * normalTangent.z);
				fixed3 lightDirWorld = _WorldSpaceLightPos0.xyz;
				half nl = dot(normalWorld, lightDirWorld)*0.5 + 0.5;
				col.rgb *= nl * _LightColor0;
				return col;
            }
            ENDCG
        }
    }
}
