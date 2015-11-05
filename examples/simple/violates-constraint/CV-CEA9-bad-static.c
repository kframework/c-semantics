// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include<stddef.h>
int main() {
  int x[2] = {0};
  void *y = &x[1];
  void *z = &x[0];
  ptrdiff_t diff = y - z;
  return 0;
}
