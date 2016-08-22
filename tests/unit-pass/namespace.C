namespace foo {
    typedef int bar;
}

inline namespace x {}

int main() {
  foo::bar x = 0;
  return x;
}
