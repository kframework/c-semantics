#ifndef _KCC_MATH_H
#define _KCC_MATH_H
#include <kcc_settings.h>

// math.h (real c99 needs -lm to get math library linked in)
double sqrt(double x);
double cos(double x);
double sin(double x);
int abs(int num);
double fabs(double arg);
double pow(double x, double y);
double exp(double x);
double log(double x);
double atan(double x);
double floor(double x);
double tan(double x);
double fmod(double x, double y);
double atan2(double y, double x);
double asin(double x);

// added by Edgar Pek (2015-7-28) for OpenPilot
float fabsf(float x);
float sinf(float x);
float asinf(float x);
float cosf(float x);
float tanf(float x);
float atan2f(float x, float y);
// -----------------------------------------------

#endif
