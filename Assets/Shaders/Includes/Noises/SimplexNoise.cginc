// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef SIMPLEX_NOISE_INCLUDED
#define SIMPLEX_NOISE_INCLUDED

inline float _SimplexNoisePermute(float x) { return floor(fmod(((x*34.0) + 1.0)*x, 289.0)); }
inline float3 _SimplexNoisePermute(float3 x) { return fmod(((x*34.0) + 1.0)*x, 289.0); }
inline float4 _SimplexNoisePermute(float4 x) { return fmod(((x*34.0) + 1.0)*x, 289.0); }
inline float4 _SimplexNoiseTaylorInvSqrt(float4 r) { return 1.79284291400159 - 0.85373472095314 * r; }
inline float _SimplexNoiseTaylorInvSqrt(float r) { return 1.79284291400159 - 0.85373472095314 * r; }

// Simplex 2D noise
//
float SimplexNoise(float2 v) {
	const float4 C = float4(0.211324865405187, 0.366025403784439,
		-0.577350269189626, 0.024390243902439);
	float2 i = floor(v + dot(v, C.yy));
	float2 x0 = v - i + dot(i, C.xx);
	float2 i1;
	i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
	float4 x12 = x0.xyxy + C.xxzz;
	x12.xy -= i1;
	i = fmod(i, 289.0);
	float3 p = _SimplexNoisePermute(_SimplexNoisePermute(i.y + float3(0.0, i1.y, 1.0))
		+ i.x + float3(0.0, i1.x, 1.0));
	float3 m = max(0.5 - float3(dot(x0, x0), dot(x12.xy, x12.xy),
		dot(x12.zw, x12.zw)), 0.0);
	m = m * m;
	m = m * m;
	float3 x = 2.0 * frac(p * C.www) - 1.0;
	float3 h = abs(x) - 0.5;
	float3 ox = floor(x + 0.5);
	float3 a0 = x - ox;
	m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h * h);
	float3 g;
	g.x = a0.x  * x0.x + h.x  * x0.y;
	g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	return 130.0 * dot(m, g);
}

//	Simplex 3D Noise 
//	by Ian McEwan, Ashima Arts
//
float SimplexNoise(float3 v) {
	const float2  C = float2(1.0 / 6.0, 1.0 / 3.0);
	const float4  D = float4(0.0, 0.5, 1.0, 2.0);

	// First corner
	float3 i = floor(v + dot(v, C.yyy));
	float3 x0 = v - i + dot(i, C.xxx);

	// Other corners
	float3 g = step(x0.yzx, x0.xyz);
	float3 l = 1.0 - g;
	float3 i1 = min(g.xyz, l.zxy);
	float3 i2 = max(g.xyz, l.zxy);

	//  x0 = x0 - 0. + 0.0 * C 
	float3 x1 = x0 - i1 + 1.0 * C.xxx;
	float3 x2 = x0 - i2 + 2.0 * C.xxx;
	float3 x3 = x0 - 1. + 3.0 * C.xxx;

	// Permutations
	i = fmod(i, 289.0);
	float4 p = _SimplexNoisePermute(_SimplexNoisePermute(_SimplexNoisePermute(
		i.z + float4(0.0, i1.z, i2.z, 1.0))
		+ i.y + float4(0.0, i1.y, i2.y, 1.0))
		+ i.x + float4(0.0, i1.x, i2.x, 1.0));

	// Gradients
	// ( N*N points uniformly over a square, mapped onto an octahedron.)
	float n_ = 1.0 / 7.0; // N=7
	float3  ns = n_ * D.wyz - D.xzx;

	float4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  fmod(p,N*N)

	float4 x_ = floor(j * ns.z);
	float4 y_ = floor(j - 7.0 * x_);    // fmod(j,N)

	float4 x = x_ * ns.x + ns.yyyy;
	float4 y = y_ * ns.x + ns.yyyy;
	float4 h = 1.0 - abs(x) - abs(y);

	float4 b0 = float4(x.xy, y.xy);
	float4 b1 = float4(x.zw, y.zw);

	float4 s0 = floor(b0)*2.0 + 1.0;
	float4 s1 = floor(b1)*2.0 + 1.0;
	float4 sh = -step(h, float4(0.0));

	float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
	float4 a1 = b1.xzyw + s1.xzyw*sh.zzww;

	float3 p0 = float3(a0.xy, h.x);
	float3 p1 = float3(a0.zw, h.y);
	float3 p2 = float3(a1.xy, h.z);
	float3 p3 = float3(a1.zw, h.w);

	//Normalise gradients
	float4 norm = _SimplexNoiseTaylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;

	// Mix final noise value
	float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
	m = m * m;
	return 42.0 * dot(m*m, float4(dot(p0, x0), dot(p1, x1),
		dot(p2, x2), dot(p3, x3)));
}

//	Simplex 4D Noise 
//	by Ian McEwan, Ashima Arts
//
float4 _SimplexNoiseGrad4(float j, float4 ip) {
	const float4 ones = float4(1.0, 1.0, 1.0, -1.0);
	float4 p, s;

	p.xyz = floor(frac(float3(j) * ip.xyz) * 7.0) * ip.z - 1.0;
	p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
	//s = float4(lessThan(p, float4(0.0)));
	//p.xyz = p.xyz + (s.xyz*2.0 - 1.0) * s.www;
	// GLSL: lessThan(x, y) = x < y
	// HLSL: 1 - step(y, x) = x < y

	s = float4(
	    1 - step(0.0, p)
	);
	p.xyz = p.xyz + (s.xyz * 2.0 - 1.0) * s.www;
	return p;
}

float SimplexNoise(float4 v) {
	const float2  C = float2(0.138196601125010504,  // (5 - sqrt(5))/20  G4
		0.309016994374947451); // (sqrt(5) - 1)/4   F4
	// First corner
	float4 i = floor(v + dot(v, C.yyyy));
	float4 x0 = v - i + dot(i, C.xxxx);

	// Other corners

	// Rank sorting originally contributed by Bill Licea-Kane, AMD (formerly ATI)
	float4 i0;

	float3 isX = step(x0.yzw, x0.xxx);
	float3 isYZ = step(x0.zww, x0.yyz);
	//  i0.x = dot( isX, float3( 1.0 ) );
	i0.x = isX.x + isX.y + isX.z;
	i0.yzw = 1.0 - isX;

	//  i0.y += dot( isYZ.xy, float2( 1.0 ) );
	i0.y += isYZ.x + isYZ.y;
	i0.zw += 1.0 - isYZ.xy;

	i0.z += isYZ.z;
	i0.w += 1.0 - isYZ.z;

	// i0 now contains the unique values 0,1,2,3 in each channel
	float4 i3 = clamp(i0, 0.0, 1.0);
	float4 i2 = clamp(i0 - 1.0, 0.0, 1.0);
	float4 i1 = clamp(i0 - 2.0, 0.0, 1.0);

	//  x0 = x0 - 0.0 + 0.0 * C 
	float4 x1 = x0 - i1 + 1.0 * C.xxxx;
	float4 x2 = x0 - i2 + 2.0 * C.xxxx;
	float4 x3 = x0 - i3 + 3.0 * C.xxxx;
	float4 x4 = x0 - 1.0 + 4.0 * C.xxxx;

	// Permutations
	i = fmod(i, 289.0);
	float j0 = _SimplexNoisePermute(_SimplexNoisePermute(_SimplexNoisePermute(_SimplexNoisePermute(i.w) + i.z) + i.y) + i.x);
	float4 j1 = _SimplexNoisePermute(_SimplexNoisePermute(_SimplexNoisePermute(_SimplexNoisePermute(
		i.w + float4(i1.w, i2.w, i3.w, 1.0))
		+ i.z + float4(i1.z, i2.z, i3.z, 1.0))
		+ i.y + float4(i1.y, i2.y, i3.y, 1.0))
		+ i.x + float4(i1.x, i2.x, i3.x, 1.0));
	// Gradients
	// ( 7*7*6 points uniformly over a cube, mapped onto a 4-octahedron.)
	// 7*7*6 = 294, which is close to the ring size 17*17 = 289.

	float4 ip = float4(1.0 / 294.0, 1.0 / 49.0, 1.0 / 7.0, 0.0);

	float4 p0 = _SimplexNoiseGrad4(j0, ip);
	float4 p1 = _SimplexNoiseGrad4(j1.x, ip);
	float4 p2 = _SimplexNoiseGrad4(j1.y, ip);
	float4 p3 = _SimplexNoiseGrad4(j1.z, ip);
	float4 p4 = _SimplexNoiseGrad4(j1.w, ip);

	// Normalise gradients
	float4 norm = _SimplexNoiseTaylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;
	p4 *= _SimplexNoiseTaylorInvSqrt(dot(p4, p4));

	// Mix contributions from the five corners
	float3 m0 = max(0.6 - float3(dot(x0, x0), dot(x1, x1), dot(x2, x2)), 0.0);
	float2 m1 = max(0.6 - float2(dot(x3, x3), dot(x4, x4)), 0.0);
	m0 = m0 * m0;
	m1 = m1 * m1;
	return 49.0 * (dot(m0*m0, float3(dot(p0, x0), dot(p1, x1), dot(p2, x2)))
		+ dot(m1*m1, float2(dot(p3, x3), dot(p4, x4))));

}

// 	<www.shadertoy.com/view/XsX3zB>
//	by Nikita Miropolskiy

/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
float3 _SimplexNoiseRandom3(float3 c) {
	float j = 4096.0*sin(dot(c, float3(17.0, 59.4, 15.0)));
	float3 r;
	r.z = frac(512.0*j);
	j *= .125;
	r.x = frac(512.0*j);
	j *= .125;
	r.y = frac(512.0*j);
	return r - 0.5;
}

const float F3 = 0.3333333;
const float G3 = 0.1666667;
float SimplexNoiseNM(float3 p) {

	float3 s = floor(p + dot(p, float3(F3)));
	float3 x = p - s + dot(s, float3(G3));

	float3 e = step(float3(0.0), x - x.yzx);
	float3 i1 = e * (1.0 - e.zxy);
	float3 i2 = 1.0 - e.zxy*(1.0 - e);

	float3 x1 = x - i1 + G3;
	float3 x2 = x - i2 + 2.0*G3;
	float3 x3 = x - 1.0 + 3.0*G3;

	float4 w, d;

	w.x = dot(x, x);
	w.y = dot(x1, x1);
	w.z = dot(x2, x2);
	w.w = dot(x3, x3);

	w = max(0.6 - w, 0.0);

	d.x = dot(_SimplexNoiseRandom3(s), x);
	d.y = dot(_SimplexNoiseRandom3(s + i1), x1);
	d.z = dot(_SimplexNoiseRandom3(s + i2), x2);
	d.w = dot(_SimplexNoiseRandom3(s + 1.0), x3);

	w *= w;
	w *= w;
	d *= w;

	return dot(d, float4(52.0));
}

float SimplexNoiseFractal(float3 m) {
	return   0.5333333* SimplexNoiseNM(m)
		+ 0.2666667* SimplexNoiseNM(2.0*m)
		+ 0.1333333* SimplexNoiseNM(4.0*m)
		+ 0.0666667* SimplexNoiseNM(8.0*m);
}




#endif //SIMPLEX_NOISE_INCLUDED
