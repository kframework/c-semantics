#include<stdlib.h>

typedef unsigned int t;

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
  t z : 1;
};

int main() {
  if(sizeof(struct foo) < 10)
      abort();
  return 0;
}
