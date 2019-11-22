#ifndef __COLORUTILS___
#define __COLORUTILS___

//变亮 
float3 Color_Lighten(float3 a, float3 b) 
{
	return max(a, b);
}

//变暗
float3 Color_Darken(float3 a, float3 b)
{
	return min(a, b);
}

//正片叠底
float3 Color_Multiply(float3 a, float3 b)
{
	return a*b;
}

//平均
float3 Color_Average(float3 a, float3 b)
{
	return (a + b)*0.5;
}

//相加。线性减淡
float3 Color_Add(float3 a, float3 b)
{
	return  min((a+b),float3(1,1,1));
}

//相减。线性加深
float3 Color_Subtract(float3 a, float3 b)
{
	return  max((a + b-1), float3(0, 0, 0));
}

//相差
float3 Color_Difference(float3 a, float3 b)
{
	return  abs(a-b);
}

//相反
float3 Color_Negation(float3 a, float3 b)
{
	return  1-abs(1-a-b);
}

//滤色
float3 Color_Screen(float3 a, float3 b)
{
	return  1 - (1-a)*(1-b);
}

//排除
float3 Color_Exclusion(float3 a, float3 b)
{
	return  a+b-2*a*b;
}

//排除
float3 Color_Overlay(float3 a, float3 b)
{
	return b < 0.5 ? 2 * a*b : (1 - 2 * (1 - a)*(1 - b));
}


#endif //__COLORUTILS___
