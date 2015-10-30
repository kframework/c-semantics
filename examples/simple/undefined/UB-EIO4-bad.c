// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int main() {
  volatile int x;
  int *y = (int *)&x;
  *y = 5;
  return 0;
}
