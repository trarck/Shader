/*=============================================================================
	FastMath.cginc: Math shader code
=============================================================================*/
  
#ifndef __PBS_MATH___
#define __PBS_MATH___

/******************************************************************************
    Shader Fast Math Lib (v0.41)
    A shader math library for optimized approximate transcendental functions.
    Optimized and tested on AMD GCN architecture.
********************************************************************************/

/******************************************************************************
    The MIT License (MIT)
    Copyright (c) <2014> <Michal Drobot>
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
********************************************************************************/

//
// Normalized range [0,1] Constants
//
#define IEEE_INT_RCP_CONST_NR0_SNORM        0x7EEF370B
#define IEEE_INT_SQRT_CONST_NR0_SNORM       0x1FBD1DF5
#define IEEE_INT_RCP_SQRT_CONST_NR0_SNORM   0x5F341A43


// Relative error : ~3.4% over full
// Precise format : ~small float
// 2 ALU
float rsqrtFast( float x )
{
#if !GL3_PROFILE
	int i = asint(x);
	i = 0x5f3759df - (i >> 1);
	return asfloat(i);
#else
	return rsqrt(x);
#endif
}

// Relative error : < 0.7% over full
// Precise format : ~small float
// 1 ALU
float sqrtFast( float x )
{
#if !GL3_PROFILE
	int i = asint(x);
	i = 0x1FBD1DF5 + (i >> 1);
	return asfloat(i);
#else
	return sqrt(x);
#endif
}

// Relative error : < 0.4% over full
// Precise format : ~small float
// 1 ALU
float rcpFast( float x )
{
#if !GL3_PROFILE
	int i = asint(x);
	i = 0x7EF311C2 - i;
	return asfloat(i);
#else
	return rcp(x);
#endif
}

// Using 1 Newton Raphson iterations
// Relative error : < 0.02% over full
// Precise format : ~half float
// 3 ALU
float rcpFastNR1( float x )
{
#if !GL3_PROFILE
	int i = asint(x);
	i = 0x7EF311C3 - i;
	float xRcp = asfloat(i);
	xRcp = xRcp * (-xRcp * x + 2.0f);
	return xRcp;
#else
	return rcp(x);
#endif
}

float lengthFast( float3 v )
{
	float LengthSqr = dot(v,v);
	return sqrtFast( LengthSqr );
}

float3 normalizeFast( float3 v )
{
	float LengthSqr = dot(v,v);
	return v * rsqrtFast( LengthSqr );
}

float4 fastClamp(float4 x, float4 Min, float4 Max)
{
#if PS4_PROFILE  
	// Warning: only correct if Min is smaller than Max
	return med3(x, Min, Max);
#else
	return clamp(x, Min, Max);
#endif
}

float3 fastClamp(float3 x, float3 Min, float3 Max)
{
#if PS4_PROFILE  
	// Warning: only correct if Min is smaller than Max
	return med3(x, Min, Max);
#else
	return clamp(x, Min, Max);
#endif
}

float2 fastClamp(float2 x, float2 Min, float2 Max)
{
#if PS4_PROFILE  
	// Warning: only correct if Min is smaller than Max
	return med3(x, Min, Max);
#else
	return clamp(x, Min, Max);
#endif
}

float fastClamp(float x, float Min, float Max)
{
#if PS4_PROFILE  
	// Warning: only correct if Min is smaller than Max
	return med3(x, Min, Max);
#else
	return clamp(x, Min, Max);
#endif
}

//
// Trigonometric functions
//

// max absolute error 9.0x10^-3
// Eberly's polynomial degree 1 - respect bounds
// 4 VGPR, 12 FR (8 FR, 1 QR), 1 scalar
// input [-1, 1] and output [0, PI]
float acosFast(float inX) 
{
    float x = abs(inX);
    float res = -0.156583f * x + (0.5 * PI);
    res *= sqrt(1.0f - x);
    return (inX >= 0) ? res : PI - res;
}

// Same cost as acosFast + 1 FR
// Same error
// input [-1, 1] and output [-PI/2, PI/2]
float asinFast( float x )
{
    return (0.5 * PI) - acosFast(x);
}

// max absolute error 1.3x10^-3
// Eberly's odd polynomial degree 5 - respect bounds
// 4 VGPR, 14 FR (10 FR, 1 QR), 2 scalar
// input [0, infinity] and output [0, PI/2]
float atanFastPos( float x ) 
{ 
    float t0 = (x < 1.0f) ? x : 1.0f / x;
    float t1 = t0 * t0;
    float poly = 0.0872929f;
    poly = -0.301895f + poly * t1;
    poly = 1.0f + poly * t1;
    poly = poly * t0;
    return (x < 1.0f) ? poly : (0.5 * PI) - poly;
}

// 4 VGPR, 16 FR (12 FR, 1 QR), 2 scalar
// input [-infinity, infinity] and output [-PI/2, PI/2]
float atanFast( float x )
{
    float t0 = atanFastPos( abs(x) );
    return (x < 0) ? -t0: t0;
}

float atan2Fast( float y, float x )
{
	float t0 = max( abs(x), abs(y) );
	float t1 = min( abs(x), abs(y) );
	float t3 = t1 / t0;
	float t4 = t3 * t3;

	// Same polynomial as atanFastPos
	t0 =         + 0.0872929;
	t0 = t0 * t4 - 0.301895;
	t0 = t0 * t4 + 1.0;
	t3 = t0 * t3;

	t3 = abs(y) > abs(x) ? (0.5 * PI) - t3 : t3;
	t3 = x < 0 ? PI - t3 : t3;
	t3 = y < 0 ? -t3 : t3;

	return t3;
}

// 4th order polynomial approximation
// 4 VGRP, 16 ALU Full Rate
// 7 * 10^-5 radians precision
// Reference : Handbook of Mathematical Functions (chapter : Elementary Transcendental Functions), M. Abramowitz and I.A. Stegun, Ed.
float acosFast4(float inX)
{
	float x1 = abs(inX);
	float x2 = x1 * x1;
	float x3 = x2 * x1;
	float s;

	s = -0.2121144f * x1 + 1.5707288f;
	s = 0.0742610f * x2 + s;
	s = -0.0187293f * x3 + s;
	s = sqrt(1.0f - x1) * s;

	// acos function mirroring
	// check per platform if compiles to a selector - no branch neeeded
	return inX >= 0.0f ? s : PI - s;
}

// 4th order polynomial approximation
// 4 VGRP, 16 ALU Full Rate
// 7 * 10^-5 radians precision 
float asinFast4( float x )
{
	return (0.5 * PI) - acosFast4(x);
}

// @param A doesn't have to be normalized, output could be NaN if this is near 0,0,0
// @param B doesn't have to be normalized, output could be NaN if this is near 0,0,0
// @return can be passed to a acosFast() or acos() to compute an angle
float CosBetweenVectors(float3 A, float3 B)
{
	// unoptimized: dot(normalize(A), normalize(B))
	return dot(A, B) * rsqrt(length2(A) * length2(B));
}

// @param A doesn't have to be normalized, output could be NaN if this is near 0,0,0
// @param B doesn't have to be normalized, output could be NaN if this is near 0,0,0
float AngleBetweenVectors(float3 A, float3 B)
{
	return acos(CosBetweenVectors(A, B));
}
// @param A doesn't have to be normalized, output could be NaN if this is near 0,0,0
// @param B doesn't have to be normalized, output could be NaN if this is near 0,0,0
float AngleBetweenVectorsFast(float3 A, float3 B)
{
	return acosFast(CosBetweenVectors(A, B));
}

#endif //__PBS_MATH___

