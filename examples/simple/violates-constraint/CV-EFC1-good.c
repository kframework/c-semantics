// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int *foo(void);

int main() {
  foo();
}

int x[5];

int *foo(void) {
  return x;
}
