#include <stdio.h>
#include <wchar.h>

struct s {
  int a[3];
  int c[3];
};

struct s s = {
  c: {1, 2, 3}
};

struct { char a[4]; char b[4]; } s2 = { "abc", "xyz" } ;
struct { char a[4]; char b[4]; } s3 = { "a", "x" } ;

struct { wchar_t a[4]; wchar_t b[4]; } s4 = { L"abc", L"xyz" } ;
struct { wchar_t a[4]; wchar_t b[4]; } s5 = { L"a", L"x" } ;

const struct { signed char *a; } s6 = { (signed char *) "abc" };

int main() {
      printf("s.c: %d, %d, %d\n", s.c[0], s.c[1], s.c[2]);
      printf("s2.a: '%s' s2.b: '%s' | s3.a: '%s' s3.b: '%s'\n", s2.a, s2.b, s3.a, s3.b);
      printf("s4.a: '%ls' s4.b: '%ls' | s5.a: '%ls' s5.b: '%ls'\n", s4.a, s4.b, s5.a, s5.b);
      printf("s6.a: '%s'\n", s6.a);
}
