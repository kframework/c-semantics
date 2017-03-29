extern "C" int puts(const char *);

struct C {
  const char *s;

  void bar() {
    puts(s);
  }

  static void baz(const C &c) {
    puts("Goodbye!");
  }
};

C x = {"Hello world!"};

C&& foo() {
  return reinterpret_cast<C&&>(x);
}

int main() {
  foo().bar();
  C::baz(foo());
}
