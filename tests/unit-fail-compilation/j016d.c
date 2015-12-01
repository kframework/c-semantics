// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <stddef.h>

void foo(int x, int (*y)[x + 1]) {
      sizeof(0 ? y : (int (*) [5]) NULL);
}

int main(void) {
      return 0;
}
