#include<stdbool.h>
#include<assert.h>
#include<string.h>

void _void(void);
unsigned short ushort(unsigned short);
short sshort(short x);
unsigned uint(unsigned);
int sint(int);
unsigned long ulong(unsigned long);
long slong(long);
unsigned long long ullong(unsigned long long);
long long sllong(long long);
float _float(float x);
double _double(double x);
signed char schar(signed char x);
unsigned char uchar(unsigned char);
_Bool _bool(_Bool);
char *pointer(char *x);
struct foo _foo(void);
union bar _bar(void);
union bar bar2(void);

struct foo{
  short x;
  int y;
};

union bar {
  short x[2];
  int y;
};

int main() {
  _void();
  assert(ushort(1) == 2);
  assert(sshort(-2) == -1);
  assert(uint(1) == 2);
  assert(sint(-2) == -1);
  assert(ulong(1) == 2);
  assert(slong(-2) == -1);
  assert(ullong(1) == 2);
  assert(sllong(-2) == -1);
  assert(_float(1.0) == 2.0);
  assert(_double(1.0) == 2.0);
  assert(schar(-2) == -1);
  assert(uchar(1) == 2);
  assert(_bool(true) == false);
  char x[3] = "fo";
  char *y = pointer(x);
  assert(strcmp(x, "co") == 0);
  assert(y == x);
  struct foo z = _foo();
  assert(z.x == 1);
  assert(z.y == 2);
  union bar w = _bar();
  assert(w.x[0] == 1);
  assert(w.x[1] == 2);
  w = bar2();
  assert(w.y == 5);
  return 0;
}
