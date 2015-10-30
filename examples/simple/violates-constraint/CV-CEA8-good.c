// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int main() {
  int x[2] = {0};
  int *y = &x[1];
  y--;
  return 0;
}
