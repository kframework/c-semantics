// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

#include<assert.h>

enum {
  x = 5
};

int main() {
  static_assert(x == 5, "x should be five");
  return 0;
}
