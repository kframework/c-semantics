#include<stdbool.h>

void _void(void) {
}

unsigned short ushort(unsigned short x) {
  return x + 1;
}

short sshort(short x) {
  return x + 1;
}

unsigned uint(unsigned x) {
  return x + 1;
}

int sint(int x) {
  return x + 1;
}

unsigned long ulong(unsigned long x) {
  return x + 1;
}

long slong(long x) {
  return x + 1;
}

unsigned long long ullong(unsigned long long x) {
  return x + 1;
}

long long sllong(long long x) {
  return x + 1;
}

float _float(float x) {
  return x + 1.0;
}

double _double(double x) {
  return x + 1.0;
}

signed char schar(signed char x) {
  return x + 1;
}

unsigned char uchar(unsigned char x) {
  return x + 1;
}

_Bool _bool(_Bool x) {
  return !x;
}

char incomplete[2] = {0, 1};

char *pointer(char *x) {
  x[0] = 'c';
  return x;
}

struct foo {
  short x;
  int y;
};

struct foo _foo(void) {
  struct foo x = {1, 2};
  return x;
}

union bar {
  short x[2];
  int y;
};

union bar _bar(void) {
  union bar x = {.x = {1, 2}};
  return x;
}

union bar bar2(void) {
  union bar x = {.y = 5};
  return x;
}

void bar3(union bar*x) {
  x->x[0] = 2;
}

char * func(char * (*f)(char *), char *x) {
  return f(x);
}
