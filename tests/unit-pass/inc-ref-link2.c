#include<stdio.h>

struct foo {
  int y;
} x;

void bar(struct foo *x) {
  printf("%d\n", x->y);
}
