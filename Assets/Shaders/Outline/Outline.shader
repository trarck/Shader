
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
				};

				sampler2D _MainTex;
				float4 _MainTex_ST;

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					o.worldNormal = UnityObjectToWorldNormal(v.normal);
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					// sample the texture
					fixed4 col = tex2D(_MainTex, i.uv);
					fixed3 worldNormal = normalize(i.worldNormal);
					//把光照方向归一化,如果要求不高，这里可以不归一化
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
					//fixed3 worldLightDir = _WorldSpaceLightPos0.xyz;
					half nl = 0.5* dot(i.worldNormal, worldLightDir) + 0.5;
					col.rgb *= nl * _LightColor0;
					col.rgb = fixed3(0.5, 0, 0);
					return col;
				}
				ENDCG
			}

			Pass
			{
					//剔除正面
					Cull Front

					CGPROGRAM
					//使用vert函数和frag函数
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
						//方法一：
						//在vertex阶段，每个顶点按照法线的方向偏移一部分，不过这种会造成近大远小的透视问题
						//v.vertex.xyz += v.normal * _OutlineFactor;
						//o.pos = UnityObjectToClipPos(v.vertex);

						//方法二：
						//将法线方向转换到视空间
						o.pos = UnityObjectToClipPos(v.vertex);
						float3 vnormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
						//将视空间法线xy坐标转化到投影空间
						float2 offset = TransformViewToProjection(vnormal.xy);
						//在最终投影阶段输出进行偏移操作
						o.pos.xy += offset * _OutlineFactor*o.pos.z;// 这里不乘以z了，否则值不一样导致描出的边大小不一样
						//强制修正z,使只显示外边。
						o.pos.z += _ZOffset;
						return o;
					}

					fixed4 frag(v2f i) : SV_Target
					{
						//这个Pass直接输出描边颜色
						return _OutlineColor;
					}
					ENDCG
				}
		}
}
