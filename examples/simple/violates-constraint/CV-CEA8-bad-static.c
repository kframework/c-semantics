// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int main() {
  int x[2] = {0};
  void *y = &x[1];
  y--;
  return 0;
}
