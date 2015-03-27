#include<stdio.h>
char * func(char * (*f)(char *), char *);

char *pointer(char *);

int main() {
  char foo[4] = "foo";
  printf("%s", func(pointer, foo));
  return 0;
}
