// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int g(const int* restrict a) {
      *(int*)a = 1;
      return 0;
}

int main(void) {
      int a = 5;
      return g(&a);
}
