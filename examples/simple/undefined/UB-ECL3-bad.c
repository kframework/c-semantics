// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int f(int* restrict a, int* restrict b) {
      *a = 1;
      *b = 1;
      return 0;
}

int main(void) {
      int a = 5;
      return f(&a, &a);
}
