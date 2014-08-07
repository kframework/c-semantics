#include <stdio.h>

struct X { int a; } f() { return (struct X) {5}; }

int main(void) {
      int *p = &f().a;
      //int x = f().a;
      //return x;
      printf("%p\n", p);
}
