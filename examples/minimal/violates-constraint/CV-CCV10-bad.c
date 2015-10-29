// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

struct str {int *x;};

int main(void) {
      int x = 5;
      int *p = &x;
      (struct str)p;
}
