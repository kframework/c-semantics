// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

#include<stdint.h>

int main(void) {
      short x;
      short *p = &x;
      intptr_t y;

      y = (intptr_t)p;

      return 0;
}
