typedef int type[5];

void foo(const type x) {}

struct foo {
  type x;
};

void bar(const struct foo *y) {
  foo(y->x);
}

int main() {
  return 0;
}
