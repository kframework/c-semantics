// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int main() {
  int y = 0;
  int *x = &y;
  y = *x;
  return 0;
}
