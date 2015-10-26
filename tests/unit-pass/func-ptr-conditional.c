#include<stddef.h> 

void foo() {}

typedef void (*action)(void);

int main() {
  action x = 1 ? foo : NULL;
  x();
  x = NULL;
  x = 0;
  return 0;
}
