#ifndef __COLORUTILS___
#define __COLORUTILS___

//���� 
float3 Color_Lighten(float3 a, float3 b) 
{
	return max(a, b);
}

//�䰵
float3 Color_Darken(float3 a, float3 b)
{
	return min(a, b);
}

//��Ƭ����
float3 Color_Multiply(float3 a, float3 b)
{
	return a*b;
}

//ƽ��
float3 Color_Average(float3 a, float3 b)
{
	return (a + b)*0.5;
}

//��ӡ����Լ���
float3 Color_Add(float3 a, float3 b)
{
	return  min((a+b),float3(1,1,1));
}

//��������Լ���
float3 Color_Subtract(float3 a, float3 b)
{
	return  max((a + b-1), float3(0, 0, 0));
}

//���
float3 Color_Difference(float3 a, float3 b)
{
	return  abs(a-b);
}

//�෴
float3 Color_Negation(float3 a, float3 b)
{
	return  1-abs(1-a-b);
}

//��ɫ
float3 Color_Screen(float3 a, float3 b)
{
	return  1 - (1-a)*(1-b);
}

//�ų�
float3 Color_Exclusion(float3 a, float3 b)
{
	return  a+b-2*a*b;
}

//�ų�
float3 Color_Overlay(float3 a, float3 b)
{
	return b < 0.5 ? 2 * a*b : (1 - 2 * (1 - a)*(1 - b));
}


#endif //__COLORUTILS___
