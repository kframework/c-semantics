// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

#include <limits.h>
#include <stddef.h>
#include <stdlib.h>

int main(void) {
      if (sizeof(ptrdiff_t) == sizeof(int)) {
            unsigned char *ptr0 = malloc(((unsigned)INT_MAX));

            unsigned char *ptr1 = ptr0 + (unsigned)INT_MAX;

            ptr1 - ptr0;
      }
      return 0;
}
