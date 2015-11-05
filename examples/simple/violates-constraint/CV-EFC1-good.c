// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

int *foo(void);

int main() {
  foo();
}

int x[5];

int *foo(void) {
  return x;
}
