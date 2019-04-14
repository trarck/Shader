Shader "Effect/Dissolve"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_DissolveThreshold("Dissolve Threshold",float) = 1
		_DissolveDirection("Dissolve Direction",Vector) = (1, 1, 0)
		_DissolveColor("Dissolve Color",Color)=(1,0,0,1)
		_DissolveEdgeColor("Dissolve Edge Color",Color) = (1,1,0,1)
		_DissolveColorFactor("Dissolve Color Factor",Range(0,1)) = 0.02
		_DissolveEdgeColorFactor("Dissolve Edge Color Factor",Range(0,1)) = 0.04
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			half _DissolveThreshold;
			half3 _DissolveDirection;
			fixed4 _DissolveColor;
			fixed4 _DissolveEdgeColor;
			fixed _DissolveColorFactor;
			fixed _DissolveEdgeColorFactor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
				o.worldPos = mul((float3x3)unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
			{
				float dissolveValue = dot(i.worldPos, normalize(_DissolveDirection));
				float clipValue = _DissolveThreshold - dissolveValue;
				clip(clipValue);
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed colorSign = step(_DissolveColorFactor, clipValue);
				fixed edgeSign = step(_DissolveEdgeColorFactor, clipValue);

			    half4 dissolveColor = lerp(_DissolveColor, _DissolveEdgeColor,  clipValue);
				
				col = lerp(dissolveColor, col, clipValue);

				//col = (1-s)*col+_DissolveColor * s;

                return col;
            }
            ENDCG
        }
    }
}
