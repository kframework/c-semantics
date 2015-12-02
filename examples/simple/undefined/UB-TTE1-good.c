// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <stddef.h>

int main() {
      sizeof(0 ? (int (*) [5]) NULL : NULL);
      return 0;
}

