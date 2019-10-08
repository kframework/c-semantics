#include<stdlib.h>

typedef unsigned int t;

struct foo {
  unsigned int : 1;
  unsigned int : 0;
  unsigned int : 1;
  unsigned int : 0;
  unsigned int : 1;
  unsigned int : 0;
  unsigned int : 1;
  unsigned int : 0;
  unsigned int : 1;
  unsigned int : 0;
  unsigned int : 1;
  unsigned int : 0;
  unsigned int : 1;
  unsigned int : 0;
  unsigned int : 1;
  unsigned int : 0;
  unsigned int : 1;
  unsigned int : 0;
  t z : 1;
};

int main() {
  if(sizeof(struct foo) < 10)
      abort();
  return 0;
}
