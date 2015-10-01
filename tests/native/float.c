#include<math.h>
#include<assert.h>
#include<float.h>
#include<stdio.h>

int main() {
  float x = fabs(-1.0);
  assert(x == 1.0);
  x = fabs(-12357.572f);
  assert(x == 12357.572f);
  x = fabs(-1.0 / 0.0);
  assert(x == 1.0 / 0.0);
  x = fabs(0.0 / 0.0);
  assert(x != x);
  x = fabs(-FLT_MIN);
  assert(x == FLT_MIN);
  x = fabs(-FLT_TRUE_MIN);
  assert(x == FLT_TRUE_MIN);
  x = fabs(-FLT_MAX);
  assert(x == FLT_MAX);
  fprintf(stdout, "%f", 1.234);
  return 0;
}
