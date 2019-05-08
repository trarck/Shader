#ifndef __COLORUTILS___
#define __COLORUTILS___

//���� 
float3 RGB_Lighten(float3 a, float3 b) 
{
	return max(a, b);
}

//�䰵
float3 RGB_Darken(float3 a, float3 b)
{
	return min(a, b);
}

//��Ƭ����
float3 RGB_Multiply(float3 a, float3 b)
{
	return a*b;
}

//ƽ��
float3 RGB_Average(float3 a, float3 b)
{
	return (a + b)*0.5;
}

//��ӡ����Լ���
float3 RGB_Add(float3 a, float3 b)
{
	return  min((a+b),float3(1,1,1));
}

//��������Լ���
float3 RGB_Subtract(float3 a, float3 b)
{
	return  max((a + b-1), float3(0, 0, 0));
}

//���
float3 RGB_Difference(float3 a, float3 b)
{
	return  abs(a-b);
}

//�෴
float3 RGB_Negation(float3 a, float3 b)
{
	return  1-abs(1-a-b);
}

//��ɫ
float3 RGB_Screen(float3 a, float3 b)
{
	return  1 - (1-a)*(1-b);
}

//�ų�
float3 RGB_Exclusion(float3 a, float3 b)
{
	return  a+b-2*a*b;
}

//�ų�
float3 RGB_Overlay(float3 a, float3 b)
{
	float3 c = 2 * a*b;
	float3 d = 1 - 2 * (1 - a)*(1 - b);
	d = 1 - 2 * ��1 - a - b + a * b) = 1 - 2 + 2a + 2b - 2 * a*b;
	=2*(a+b-0.5)-2*a*b
}


#endif //__COLORUTILS___
