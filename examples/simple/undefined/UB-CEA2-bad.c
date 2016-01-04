// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <limits.h>
#include <stddef.h>
#include <stdlib.h>

int main(void) {
      if (sizeof(ptrdiff_t) == sizeof(long)) {
            unsigned char *ptr0 = malloc(((unsigned long)LONG_MAX) + 1);

            unsigned char *ptr1 = ptr0 + (unsigned long)LONG_MAX + 1;

            ptr1 - ptr0;
      }
      return 0;
}
