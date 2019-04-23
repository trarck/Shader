/*=============================================================================
	FastMath.cginc: Math shader code
=============================================================================*/
  
#ifndef __PBS_COMMON___
#define __PBS_COMMON___

#define PI 3.1415926535897932

// Clamp the base, so it's never <= 0.0f (INF/NaN).
float ClampedPow(float X, float Y)
{
	return pow(max(abs(X), 0.000001f), Y);
}
float2 ClampedPow(float2 X, float2 Y)
{
	return pow(max(abs(X), float2(0.000001f, 0.000001f)), Y);
}
float3 ClampedPow(float3 X, float3 Y)
{
	return pow(max(abs(X), float3(0.000001f, 0.000001f, 0.000001f)), Y);
}

float4 ClampedPow(float4 X, float4 Y)
{
	return pow(max(abs(X), float4(0.000001f, 0.000001f, 0.000001f, 0.000001f)), Y);
}

float Square(float x)
{
	return x * x;
}

float2 Square(float2 x)
{
	return x * x;
}

float3 Square(float3 x)
{
	return x * x;
}

float4 Square(float4 x)
{
	return x * x;
}


float Pow2(float x)
{
	return x * x;
}

float2 Pow2(float2 x)
{
	return x * x;
}

float3 Pow2(float3 x)
{
	return x * x;
}

float4 Pow2(float4 x)
{
	return x * x;
}

float Pow3(float x)
{
	return x * x*x;
}

float2 Pow3(float2 x)
{
	return x * x*x;
}

float3 Pow3(float3 x)
{
	return x * x*x;
}

float4 Pow3(float4 x)
{
	return x * x*x;
}

float Pow4(float x)
{
	float xx = x * x;
	return xx * xx;
}

float2 Pow4(float2 x)
{
	float2 xx = x * x;
	return xx * xx;
}

float3 Pow4(float3 x)
{
	float3 xx = x * x;
	return xx * xx;
}

float4 Pow4(float4 x)
{
	float4 xx = x * x;
	return xx * xx;
}

float Pow5(float x)
{
	float xx = x * x;
	return xx * xx * x;
}

float2 Pow5(float2 x)
{
	float2 xx = x * x;
	return xx * xx * x;
}

float3 Pow5(float3 x)
{
	float3 xx = x * x;
	return xx * xx * x;
}

float4 Pow5(float4 x)
{
	float4 xx = x * x;
	return xx * xx * x;
}

float Pow6(float x)
{
	float xx = x * x;
	return xx * xx * xx;
}

float2 Pow6(float2 x)
{
	float2 xx = x * x;
	return xx * xx * xx;
}

float3 Pow6(float3 x)
{
	float3 xx = x * x;
	return xx * xx * xx;
}

float4 Pow6(float4 x)
{
	float4 xx = x * x;
	return xx * xx * xx;
}



float3 RGBToYCoCg(float3 RGB)
{
	float Y = dot(RGB, float3(1, 2, 1)) * 0.25;
	float Co = dot(RGB, float3(2, 0, -2)) * 0.25 + (0.5 * 256.0 / 255.0);
	float Cg = dot(RGB, float3(-1, 2, -1)) * 0.25 + (0.5 * 256.0 / 255.0);

	float3 YCoCg = float3(Y, Co, Cg);
	return YCoCg;
}

float3 YCoCgToRGB(float3 YCoCg)
{
	float Y = YCoCg.x;
	float Co = YCoCg.y - (0.5 * 256.0 / 255.0);
	float Cg = YCoCg.z - (0.5 * 256.0 / 255.0);

	float R = Y + Co - Cg;
	float G = Y + Cg;
	float B = Y - Co - Cg;

	float3 RGB = float3(R, G, B);
	return RGB;
}

// Octahedron Normal Vectors
// [Cigolle 2014, "A Survey of Efficient Representations for Independent Unit Vectors"]
//						Mean	Max
// oct		8:8			0.33709 0.94424
// snorm	8:8:8		0.17015 0.38588
// oct		10:10		0.08380 0.23467
// snorm	10:10:10	0.04228 0.09598
// oct		12:12		0.02091 0.05874

float2 UnitVectorToOctahedron(float3 N)
{
	N.xy /= dot(1, abs(N));
	if (N.z <= 0)
	{
		N.xy = (1 - abs(N.yx)) * (N.xy >= 0 ? float2(1, 1) : float2(-1, -1));
	}
	return N.xy;
}

float3 OctahedronToUnitVector(float2 Oct)
{
	float3 N = float3(Oct, 1 - dot(1, abs(Oct)));
	if (N.z < 0)
	{
		N.xy = (1 - abs(N.yx)) * (N.xy >= 0 ? float2(1, 1) : float2(-1, -1));
	}
	return normalize(N);
}

float2 UnitVectorToHemiOctahedron(float3 N)
{
	N.xy /= dot(1, abs(N));
	return float2(N.x + N.y, N.x - N.y);
}

float3 HemiOctahedronToUnitVector(float2 Oct)
{
	Oct = float2(Oct.x + Oct.y, Oct.x - Oct.y) * 0.5;
	float3 N = float3(Oct, 1 - dot(1, abs(Oct)));
	return normalize(N);
}

float3 Pack1212To888(float2 x)
{
	// Pack 12:12 to 8:8:8
#if 0
	uint2 x1212 = (uint2)(x * 4095.0);
	uint2 High = x1212 >> 8;
	uint2 Low = x1212 & 255;
	uint3 x888 = uint3(Low, High.x | (High.y << 4));
	return x888 / 255.0;
#else
	float2 x1212 = floor(x * 4095);
	float2 High = floor(x1212 / 256);	// x1212 >> 8
	float2 Low = x1212 - High * 256;	// x1212 & 255
	float3 x888 = float3(Low, High.x + High.y * 16);
	return saturate(x888 / 255);
#endif
}

float2 Pack888To1212(float3 x)
{
	// Pack 8:8:8 to 12:12
#if 0
	uint3 x888 = (uint3)(x * 255.0);
	uint High = x888.z >> 4;
	uint Low = x888.z & 15;
	uint2 x1212 = x888.xy | uint2(Low << 8, High << 8);
	return x1212 / 4095.0;
#else
	float3 x888 = floor(x * 255);
	float High = floor(x888.z / 16);	// x888.z >> 4
	float Low = x888.z - High * 16;		// x888.z & 15
	float2 x1212 = x888.xy + float2(Low, High) * 256;
	return saturate(x1212 / 4095);
#endif
}

float3 EncodeNormal(float3 N)
{
	return N * 0.5 + 0.5;
	//return Pack1212To888( UnitVectorToOctahedron( N ) * 0.5 + 0.5 );
}

float3 DecodeNormal(float3 N)
{
	return N * 2 - 1;
	//return OctahedronToUnitVector( Pack888To1212( N ) * 2 - 1 );
}

#endif //__PBS_COMMON___

