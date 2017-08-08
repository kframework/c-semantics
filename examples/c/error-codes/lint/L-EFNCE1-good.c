#include <limits.h>
void foo(int x) {
  char arr[100];
  if (x < 100) {
    foo(x+1);
  }
}

int main() {
  foo(0);
}
