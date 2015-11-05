// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int main(void) {
      int a[3] = {0};
      int b;

      int *p = &a[0] + 3;
      int *q = &b;

      if (&p <= &p) {
            return 0;
      }
}
