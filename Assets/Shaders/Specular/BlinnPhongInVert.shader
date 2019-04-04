// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/BlinnPhongInVert"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Specular("Specular",Range(1,200)) = 1
		_SpecColor("SpecColor", Color) = (1,1,1,1)
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
				half3 lightColor:COLOR;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Specular;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				//视角方向
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				worldNormal = normalize(worldNormal);
				//光的方向
				fixed3 worldLightDir = UnityWorldSpaceLightDir(worldPos);
				//慢反射
				half diffuse = 0.5* dot(worldNormal, worldLightDir) + 0.5;
				//计算半角向量
				float3 h = normalize(worldLightDir + worldViewDir);
				//计算高光
				float specular = pow(max(0, dot(worldNormal, h)), _Specular);
				o.lightColor = diffuse*_LightColor0 + _SpecColor.rgb*specular;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
			col.rgb *= i.lightColor;
			return col;
		}

		ENDCG
	}
		}
}
