// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int foo;
int *bar = &foo;

int * restrict x;

int main() {
  int *y = bar;
  x = y;
}
