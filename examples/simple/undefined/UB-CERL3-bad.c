// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int main() {
  int x;
  int y;
  if (&x > &y) {
    return 1;
  }
  return 0;
}
