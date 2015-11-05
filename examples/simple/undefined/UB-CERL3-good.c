// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int main() {
  int x[2];
  if (x + 1 > x) {
    return 0;
  }
  return 1;
}
