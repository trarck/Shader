Shader "Custom/LambertInVert"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
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
			// make fog work
			#pragma multi_compile_fog

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
				half3 diffuse : COLOR0;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				//把法线转化为世界坐标下的法线
				half3 worldNormal = UnityObjectToWorldNormal(v.normal);
				//环境光 
				//half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				//光照 
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				//漫反射光 
				fixed3 diffuse = _LightColor0.rgb * saturate(dot(worldNormal, worldLight)); 
				//摄像机方向 
				//fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul((float3x3)unity_WorldToObject, a.vertex)); 
				//反射光
				//fixed3 reflectDir = normalize(reflect(-worldLight, worldNormal));
				//高光反射 
				//fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(viewDir, reflectDir)), _Gloss); 
				//颜色
				//v.color = ambient;// +diffuse + specular;
				o.diffuse = diffuse;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				col.rgb *= i.diffuse;
				return col;
			}
			ENDCG
		}
	}
}
