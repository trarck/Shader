// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef GENERIC_NOISE_INCLUDED
#define GENERIC_NOISE_INCLUDED

//Generic Noise
inline float GenericRand(float n){
    return frac(sin(n) * 43758.5453123);
}

inline float GenericRand(float2 n) { 
	return frac(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453);
}

inline float GenericNoise(float p){
    float fl = floor(p);
    float fc = frac(p);
    return lerp(GenericRand(fl), GenericRand(fl + 1.0), fc);
}
    
float GenericNoise(float2 n) {
    const float2 d = float2(0.0, 1.0);
    float2 b = floor(n), f = smoothstep(float2(0.0), float2(1.0), frac(n));
    return lerp(lerp(GenericRand(b), GenericRand(b + d.yx), f.x), lerp(GenericRand(b + d.xy), GenericRand(b + d.yy), f.x), f.y);
}

float GenericNoise2(float2 p){
	float2 ip = floor(p);
	float2 u = frac(p);
	u = u*u*(3.0-2.0*u);
	
	float res = lerp(
		lerp(GenericRand(ip),GenericRand(ip+float2(1.0,0.0)),u.x),
		lerp(GenericRand(ip+float2(0.0,1.0)),GenericRand(ip+float2(1.0,1.0)),u.x),u.y);
	return res*res;
}

inline float _GenericMod289(float x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0; 
}

inline float4 _GenericMod289(float4 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0; 
}

inline float4 _GenericPerm(float4 x) {
	return _GenericMod289(((x * 34.0) + 1.0) * x);
}

float GenericNoise(float3 p) {
	float3 a = floor(p);
	float3 d = p - a;
	d = d * d * (3.0 - 2.0 * d);

	float4 b = a.xxyy + float4(0.0, 1.0, 0.0, 1.0);
	float4 k1 = _GenericPerm(b.xyxy);
	float4 k2 = _GenericPerm(k1.xyxy + b.zzww);

	float4 c = k2 + a.zzzz;
	float4 k3 = _GenericPerm(c);
	float4 k4 = _GenericPerm(c + 1.0);

	float4 o1 = frac(k3 * (1.0 / 41.0));
	float4 o2 = frac(k4 * (1.0 / 41.0));

	float4 o3 = o2 * d.z + o1 * (1.0 - d.z);
	float2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

	return o4.y * d.y + o4.x * (1.0 - d.y);
}

#endif //GENERIC_NOISE_INCLUDED
