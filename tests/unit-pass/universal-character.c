#include<stdio.h>
#include<string.h>
int main() {
  char *foo = "\xff\u0102\U00010203";
  printf("%d %d %d %d %d %d %d %lu\n", foo[0], foo[1], foo[2], foo[3], foo[4], foo[5], foo[6], strlen(foo));
  return 0;
}
