// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int main() {
  int x = 0;
  float y = 0.0;
  int *z = 1 ? &x : &y;
  return 0;
}
