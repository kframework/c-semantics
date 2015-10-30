// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int f(int n) { return n; }

int main(void) {
      1 ? (int(*)[f(5)]) 0 : (int (*)[3]) 0;
      return 0;
}
