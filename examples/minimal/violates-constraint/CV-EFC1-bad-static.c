typedef int arr[5];

arr foo(void);

int main() {
  foo();
}

int x[5];

arr foo(void) {
  return x;
}
