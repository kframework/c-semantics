int *foo(void);

int main() {
  foo();
}

int x[5];

int *foo(void) {
  return x;
}
