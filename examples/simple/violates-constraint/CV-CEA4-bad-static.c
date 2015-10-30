// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int main() {
  int x = 0;
  int *y = &x;
  y = x - y;
  return 0;
}
