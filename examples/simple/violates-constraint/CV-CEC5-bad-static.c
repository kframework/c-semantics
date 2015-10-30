// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int main() {
  int x = 0;
  int *y = 1 ? &x : 1;
  return 0;
}
