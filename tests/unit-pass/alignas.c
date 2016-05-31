#include <stdalign.h>
#include <assert.h>
struct S {
      int a;
      char b;
      alignas(char)          char c;
      alignas(int)           char d;
      alignas(long int)      char e;
      alignas(long long int) char f;
      alignas(float)         char g;
      alignas(double)        char h;
} s;

struct {
      struct S s;
} t;

int main(void) {

      int a;
      char b;
      alignas(char)          char c;
      alignas(int)           char d;
      alignas(long int)      char e;
      alignas(long long int) char f;
      alignas(float)         char g;
      alignas(double)        char h;

      assert(alignof(s.a) == alignof(int));
      assert(alignof(s.b) == alignof(char));
      assert(alignof(s.c) == alignof(char));
      assert(alignof(s.d) == alignof(int));
      assert(alignof(s.e) == alignof(long int));
      assert(alignof(s.f) == alignof(long long int));
      assert(alignof(s.g) == alignof(float));
      assert(alignof(s.h) == alignof(double));

      assert(alignof(t.s) == alignof(struct S));
      assert(alignof(t) >= alignof(struct S));

      assert(alignof(a) == alignof(int));
      assert(alignof(b) == alignof(char));
      assert(alignof(c) == alignof(char));
      assert(alignof(d) == alignof(int));
      assert(alignof(e) == alignof(long int));
      assert(alignof(f) == alignof(long long int));
      assert(alignof(g) == alignof(float));
      assert(alignof(h) == alignof(double));

      return 0;
}
