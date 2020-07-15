// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int main() {
  int x = 0;
  int c = 1;
  int *y = c ? &x : 2;
  return 0;
}
