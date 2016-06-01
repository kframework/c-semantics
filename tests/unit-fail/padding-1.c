#include<stdio.h>
struct { char x; int y; } s;
int main() {
  char *ptr = (char *)&s;
  ptr[1] = 'F';
  s.x = 0;
  printf("%d", ptr[1]);
}
