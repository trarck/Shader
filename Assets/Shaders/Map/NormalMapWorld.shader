Shader "Custom/NormalWorld"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "white" {}
		_NormalScale("Normal scale",Float) = 1.0
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 300

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
				half4 tangent   : TANGENT;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 tangentToWorld[3] : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NormalMap;
			float _NormalScale;

			half3 UnpackScaleNormal(half4 packednormal, half bumpScale)
			{
				#if defined(UNITY_NO_DXT5nm)
					half3 normal = packednormal.xyz * 2 - 1;
					#if (SHADER_TARGET >= 30)
						// SM2.0: instruction count limitation
						// SM2.0: normal scaler is not supported
						normal.xy *= bumpScale;
					#endif
					return normal;
				#else
					// This do the trick
					packednormal.x *= packednormal.w;

					half3 normal;
					normal.xy = (packednormal.xy * 2 - 1);
					#if (SHADER_TARGET >= 30)
						// SM2.0: instruction count limitation
						// SM2.0: normal scaler is not supported
						normal.xy *= bumpScale;
					#endif
					normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
					return normal;
				#endif
			}

			v2f vert(appdata v)
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

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				half3 normalTangent = UnpackScaleNormal(tex2D(_NormalMap, i.uv),_NormalScale);
				float3 normalWorld = normalize(i.tangentToWorld[0].xyz * normalTangent.x + i.tangentToWorld[1] * normalTangent.y + i.tangentToWorld[2] * normalTangent.z);
				fixed3 lightDirWorld = _WorldSpaceLightPos0.xyz;
				half nl = dot(normalWorld, lightDirWorld)*0.5+0.5;
				col.rgb *= nl * _LightColor0;
				return col;
			}
			ENDCG
		}
	}
}
