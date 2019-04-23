Shader "Outline/Outline"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_OutlineColor("OutlineColor", Color) = (1,0,0,1)
		_OutlineFactor("OutlineFactor", Range(0,1)) = 0.1
		_ZOffset("Z Offset",float) = 0
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" }
			LOD 100

			Pass
			{
			//�޳����棬ֻ��Ⱦ���棬���ڴ����ģ�����ã����������Ҫ����ģ�����������
			Cull Front
			//�������ƫ�ƣ����passԶ�����һЩ����ֹ������pass����
			Offset 18,1
			CGPROGRAM
			//ʹ��vert������frag����
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			fixed4 _OutlineColor;
			half _OutlineFactor;
			half _ZOffset;

			struct v2f
			{
				float4 pos : SV_POSITION;
			};

			v2f vert(appdata_full v)
			{
				v2f o;
				//��vertex�׶Σ�ÿ�����㰴�շ��ߵķ���ƫ��һ���֣��������ֻ���ɽ���ԶС��͸������
				v.vertex.xyz += v.normal * _OutlineFactor;
				o.pos = UnityObjectToClipPos(v.vertex);
				////�����߷���ת�����ӿռ�
				//float3 vnormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				////���ӿռ䷨��xy����ת����ͶӰ�ռ�
				//float2 offset = TransformViewToProjection(vnormal.xy);
				////������ͶӰ�׶��������ƫ�Ʋ���
				//o.pos.xy += offset * _OutlineFactor *o.pos.z;
				//o.pos.z += _ZOffset;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				//���Passֱ����������ɫ
				return _OutlineColor;
			}
			ENDCG
		}

			Pass
			{
				Name "FORWARD"
				Tags { "LightMode" = "ForwardBase" }

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"
				#include "UnityLightingCommon.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					float3 normal:NORMAL;
					float2 uv : TEXCOORD0;
				};

				struct v2f
				{
					float2 uv : TEXCOORD0;
					float4 vertex : SV_POSITION;
					float3 worldNormal:TEXCOORD1;
					float3 p1:TEXCOORD2;
				};

				sampler2D _MainTex;
				float4 _MainTex_ST;

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					o.worldNormal = UnityObjectToWorldNormal(v.normal);
					o.p1 = o.vertex;
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					// sample the texture
					fixed4 col = tex2D(_MainTex, i.uv);
					fixed3 worldNormal = normalize(i.worldNormal);
					//�ѹ��շ����һ��,���Ҫ�󲻸ߣ�������Բ���һ��
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
					//fixed3 worldLightDir = _WorldSpaceLightPos0.xyz;
					half nl = 0.5* dot(i.worldNormal, worldLightDir) + 0.5;
					col.rgb *= nl * _LightColor0;
					col.r = i.p1.x;
					col.g = 0;
					col.b = 0;
					return col;
				}
				ENDCG
			}

			
		}
}
