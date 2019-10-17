#include <stdio.h>
#include <inttypes.h>
uintptr_t f() { 
  int a; 
  return (uintptr_t)&a; }
uintptr_t g() { 
  int a; 
  return (uintptr_t)&a; }
int main() { 
  uintptr_t g_ = g();
  uintptr_t f_ = f();
  _Bool b = (f_ == g_); // can this be true?
  //printf("(f()==g())=%s\n",b?"true":"false"); 
}
