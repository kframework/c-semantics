#include<stdlib.h>

struct foo {
  int : 1;
  int : 0;
  int : 1;
  int : 0;
  int : 1;
  int : 0;
  int : 1;
  int : 0;
  int : 1;
  int : 0;
  int : 1;
  int : 0;
  int : 1;
  int : 0;
  int : 1;
  int : 0;
  int : 1;
  int : 0;
  int z : 1;
};

int main() {
  if(sizeof(struct foo) < 10)
      abort();
  return 0;
}
