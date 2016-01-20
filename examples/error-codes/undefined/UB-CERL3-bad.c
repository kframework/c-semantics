// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int main() {
  int x;
  int y;
  if (&x > &y) {
    return 0;
  }
  return 1;
}
