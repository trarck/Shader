// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/ToneShadow"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Specular("Specular",Range(1,20)) = 1
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
				float3 worldNormal:TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Specular;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				//视角方向
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				float3 worldNormal = normalize(i.worldNormal);
				//光的方向
				fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPos);
				//慢反射
				half diffuse = 0.5* dot(i.worldNormal, worldLightDir) + 0.5;

				//计算反射光方向
				float3 R = 2 * worldNormal* dot(worldNormal, worldLightDir) - worldLightDir;
				R = normalize(R);
				//R = normalize(reflect(-worldLightDir, worldNormal));

				//计算高光
				float specular = pow(max(0, dot(R, worldViewDir)), _Specular);
				half rim = 1.0 - max(0, dot(worldViewDir, worldNormal));

				col.rgb *= (diffuse*_LightColor0 + _SpecColor.rgb*specular);
				return col;
			}

			ENDCG
		}
	}
}
