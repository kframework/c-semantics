extern "C" int printf(char const *, ...);
extern "C" void abort(void);
struct A {
  int a;
  A(int a) {
    this->a = a;
    printf("Constructing A %d\n", a);
  }
  ~A() {
    printf("Destroying A %d\n", a);
  }
};

struct Y {
  Y() {
    printf("Constructing Y\n");
  }

  ~Y() noexcept(false) {
    printf("Destroying Y\n");
    throw 0;
  }
};

A f() {
  try {
    A a = 1;
    Y b;
    A c = 2;
    return 3;
  } catch(...) {}
  return 4;
}

int main() {
  A a = f();
  if (a.a != 4) abort();
}
