template<typename> class X;

template <typename T> void foo(class X<T> *t);

template <typename T> T id(T x);

template <typename T> T id2(T x) { return x; }

int main() {
  class X<int> *t = nullptr;
  foo(t);

  const char * b, * a = "abc";
  b = id(a);

  int y, x = 5;
  y = id(x);

  float g, f = 1.0;
  g = id2(f);

  return a != b || x != y || f != g;
}
