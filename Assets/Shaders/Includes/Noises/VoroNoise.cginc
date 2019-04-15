// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef VORO_NOISE_INCLUDED
#define VORO_NOISE_INCLUDED

#define OCTAVES         2			// 7
#define SWITCH_TIME 60.0 // seconds

float3 _VoroHash3(float2 p) {
	float3 q = float3(dot(p, float2(127.1, 311.7)),
		dot(p, float2(269.5, 183.3)),
		dot(p, float2(419.2, 371.9)));
	return frac(sin(q)*43758.5453);
}

float2 _VoroHash(float2 p) {
	p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
	return frac(sin(p)*43758.5453);
}

float VoroNoise(in float2 x, float u, float v) {
	float2 p = floor(x);
	float2 f = frac(x);

	float k = 1.0 + 63.0*pow(1.0 - v, 4.0);

	float va = 0.0;
	float wt = 0.0;
	for (int j = -2; j <= 2; j++)
		for (int i = -2; i <= 2; i++)
		{
			float2 g = float2(float(i), float(j));
			float3 o = _VoroHash3(p + g)*float3(u, u, 1.0);
			float2 r = g - f + o.xy;
			float d = dot(r, r);
			float ww = pow(1.0 - smoothstep(0.0, 1.414, sqrt(d)), k);
			va += o.z*ww;
			wt += ww;
		}

	return va / wt;
}

float VoroNoise(in float2 x,float t, float function1, bool multiply_by_F1, bool inverse, float distance_type) {
	float2 n = floor(x);
	float2 f = frac(x);

	float F1 = 8.0;
	float F2 = 8.0;

	for (int j = -1; j <= 1; j++)
		for (int i = -1; i <= 1; i++) {
			float2 g = float2(i, j);
			float2 o = _VoroHash(n + g);

			o = 0.5 + 0.41*sin(time + 6.2831*o);
			float2 r = g - f + o;

			float d = distance_type < 1.0 ? dot(r, r) :				// euclidean^2
				distance_type < 2.0 ? sqrt(dot(r, r)) :			// euclidean
				distance_type < 3.0 ? abs(r.x) + abs(r.y) :		// manhattan
				distance_type < 4.0 ? max(abs(r.x), abs(r.y)) :	// chebyshev
				0.0;

			if (d < F1) {
				F2 = F1;
				F1 = d;
			}
			else if (d < F2) {
				F2 = d;
			}
		}

	float c = function < 1.0 ? F1 :
		function < 2.0 ? F2 :
		function < 3.0 ? F2 - F1 :
		function < 4.0 ? (F1 + F2) / 2.0 :
		0.0;

	if (multiply_by_F1)	c *= F1;
	if (inverse)			c = 1.0 - c;

	return c;
}


float VoroFbm(in float2 p) {

	float t = _Time.y / SWITCH_TIME;
	float function1 = fmod(t, 4.0);
	bool multiply_by_F1 = (fmod(t, 8.0) >= 4.0);
	bool inverse = (fmod(t, 16.0) >= 8.0);
	float distance_type = fmod(t / 16.0, 4.0);

	float s = 0.0;
	float m = 0.0;
	float a = 0.5;

	for (int i = 0; i < OCTAVES; i++) {
		s += a * VoroNoise(p, t, function1, multiply_by_F1, inverse, distance_type);
		m += a;
		a *= 0.5;
		p *= 2.0;
	}
	return s / m;
}

#endif //VORO_NOISE_INCLUDED
