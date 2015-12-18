#include<stdio.h>
struct foo { int y; } x;
void bar(struct foo *p) {
  int *p2 = (int *)p;
  long long *p3 = (long long *)p;
}
