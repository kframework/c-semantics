// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int main(void) {
      struct {int x; } a;
      struct {int x; } b;

      int* p = &a.x;
      int* q = &b.x;

      if (&p < &p) {
            return 0;
      }
}
