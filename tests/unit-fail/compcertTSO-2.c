#include <stdio.h>
#include <inttypes.h>
uintptr_t f() { 
  int a; 
  return (uintptr_t)&a; }
uintptr_t g() { 
  int a; 
  return (uintptr_t)&a; }
int main() { 
  _Bool b = (f() == g()); // can this be true?
  //printf("(f()==g())=%s\n",b?"true":"false"); 
}
