// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

void f(int a[static 10]) { }

int main(void) {
      f((void*) 0);
      return 0;
}
