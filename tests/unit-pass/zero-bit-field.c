#include<stdlib.h>
struct foo {
  char x : 5;
  char : 1;
  char : 0;
  char z : 2;
};

int main() {
  if(sizeof(struct foo) != 2)
    abort();
  return 0;
}
