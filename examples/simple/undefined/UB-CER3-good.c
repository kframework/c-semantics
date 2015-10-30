// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int main() {
  int y = 0;
  int *x = &y;
  y = *x;
  return 0;
}
