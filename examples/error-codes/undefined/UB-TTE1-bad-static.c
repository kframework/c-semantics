// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <stddef.h>

int main(void) {
      int x = 5;
      sizeof(0 ? (int (*) [x]) NULL : (int (*) [x]) NULL);
      return 0;
}
