// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int main() {
  volatile int x;
  volatile int *y = &x;
  *y = 5;
  return 0;
}
