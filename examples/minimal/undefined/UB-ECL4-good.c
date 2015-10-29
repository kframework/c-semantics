// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

int g(const int* restrict a, int* b) {
      *b = 1;
      *a;
      return 0;
}

int main(void) {
      int a = 5;
      int b = 5;
      return g(&a, &b);
}
