// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef MM_NOISE_INCLUDED
#define MM_NOISE_INCLUDED

//	<https://www.shadertoy.com/view/4dS3Wd>
//	By Morgan McGuire @morgan3d, http://graphicscodex.com
//
float _MMHash(float n) { 
	return frac(sin(n) * 1e4); 
}

float _MMHash(float2 p) { 
	return frac(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); 
}

float MMNoise(float x) {
	float i = floor(x);
	float f = frac(x);
	float u = f * f * (3.0 - 2.0 * f);
	return lerp(_MMHash(i), _MMHash(i + 1.0), u);
}

float MMNoise(float2 x) {
	float2 i = floor(x);
	float2 f = frac(x);

	// Four corners in 2D of a tile
	float a = _MMHash(i);
	float b = _MMHash(i + float2(1.0, 0.0));
	float c = _MMHash(i + float2(0.0, 1.0));
	float d = _MMHash(i + float2(1.0, 1.0));

	// Simple 2D lerp using smoothstep envelope between the values.
	// return float3(lerp(lerp(a, b, smoothstep(0.0, 1.0, f.x)),
	//			lerp(c, d, smoothstep(0.0, 1.0, f.x)),
	//			smoothstep(0.0, 1.0, f.y)));

	// Same code, with the clamps in smoothstep and common subexpressions
	// optimized away.
	float2 u = f * f * (3.0 - 2.0 * f);
	return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// This one has non-ideal tiling properties that I'm still tuning
float MMNoise(float3 x) {
	const float3 step = float3(110, 241, 171);

	float3 i = floor(x);
	float3 f = frac(x);

	// For performance, compute the base input to a 1D _MMHash from the integer part of the argument and the 
	// incremental change to the 1D based on the 3D -> 1D wrapping
	float n = dot(i, step);

	float3 u = f * f * (3.0 - 2.0 * f);
	return lerp(lerp(lerp(_MMHash(n + dot(step, float3(0, 0, 0))), _MMHash(n + dot(step, float3(1, 0, 0))), u.x),
		lerp(_MMHash(n + dot(step, float3(0, 1, 0))), _MMHash(n + dot(step, float3(1, 1, 0))), u.x), u.y),
		lerp(lerp(_MMHash(n + dot(step, float3(0, 0, 1))), _MMHash(n + dot(step, float3(1, 0, 1))), u.x),
			lerp(_MMHash(n + dot(step, float3(0, 1, 1))), _MMHash(n + dot(step, float3(1, 1, 1))), u.x), u.y), u.z);
}

#endif //MM_NOISE_INCLUDED
