// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int main() {
  int x = 0;
  int *y = 1 ? &x : 0;
  return 0;
}
