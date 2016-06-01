#include<stdio.h>
struct s1 { char x; short y; } s1;
struct { struct s1 x; long long y; } s2;
int main() {
  s2.x = s1;
  char *ptr = (char *)&s2;
  ptr[4] = 'F';
  s2.x.x = 0;
  printf("%d", ptr[4]);
}
