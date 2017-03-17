// PR c++/36688
// { dg-do run }
// { dg-options "-O2" }
#include <stddef.h>

extern "C" int memcmp(const void *, const void *, size_t);
extern "C" void abort(void);

struct S
{
  long long a;
  long long b;
  long long c;
};

struct T
{
  S g;
  long long h[12];
};

static const S s = { 1, 2, 3 };
static const T t = { s, 0 };

int
main ()
{
  T x = t;
  if (memcmp (&x, &t, sizeof (T)))
    abort ();
}
