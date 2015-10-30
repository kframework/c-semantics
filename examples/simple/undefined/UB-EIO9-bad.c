// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

volatile struct {
  int x;
} foo;

int main() {
  int *y = (int *)&foo.x;
  return *y;
}
