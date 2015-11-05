// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include<assert.h>

int main() {
  int x = 5;
  static_assert(x == 5, "x should be five");
  return 0;
}
