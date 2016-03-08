#include<stdlib.h>
struct foo {
  int x : 1;
  int : 1;
  int : 0;
  int z : 1;
};

int main() {
  if(sizeof(struct foo) < 2)
      abort();
  return 0;
}
