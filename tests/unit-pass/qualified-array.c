void foo (const char x[100]) {
  x++;
}

int main() {
  const char x[100];
  foo(x);
}
