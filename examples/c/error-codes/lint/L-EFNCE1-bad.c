#include <limits.h>
void foo(int x) {
  char arr[INT_MAX];
  if (x < 100) {
    foo(x+1);
  }
}

int main() {
  foo(0);
}
