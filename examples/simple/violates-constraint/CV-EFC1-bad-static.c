// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

typedef int arr[5];

arr foo(void);

int main() {
  foo();
}

int x[5];

arr foo(void) {
  return x;
}
