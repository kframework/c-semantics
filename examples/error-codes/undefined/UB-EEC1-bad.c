// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int f(int n) { return n; }

int main(void) {
      1 ? (int(*)[f(5)]) 0 : (int (*)[f(3)]) 0;
      return 0;
}
