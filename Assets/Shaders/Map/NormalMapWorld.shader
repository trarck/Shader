Shader "Custom/NormalWorld"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "white" {}
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
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
				half4 tangent   : TANGENT;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 tangentToWorldAndPackedData[3] : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NormalMap;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				float3 normalWorld = UnityObjectToWorldNormal(v.normal);
				float3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);

				half sign = v.tangent.w * unity_WorldTransformParams.w;
				half3 binormal = cross(normalWorld, tangentWorld) * sign;
				return half3x3(tangent, binormal, normal);
				float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
				o.tangentToWorldAndPackedData[0].xyz = tangentWorld;
				o.tangentToWorldAndPackedData[1].xyz = binormal;
				o.tangentToWorldAndPackedData[2].xyz = normalWorld;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed3 normal = tex2D(_NormalMap, i.uv);
				//fixed3 worldLightDir = _WorldSpaceLightPos0.xyz;
				half nl = dot(normal, normalize(i.lightDir))*0.5+0.5;
				col.rgb *= nl * _LightColor0;
				return col;
			}
			ENDCG
		}
	}
}
