// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

void f(int a[static 10]) { }

int main(void) {
      int a[10];
      f(a);
      return 0;
}
