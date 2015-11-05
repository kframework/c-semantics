// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

_Alignas(1) int x = 42;

int main(void) {
      extern _Alignas(1) int x;
      return 0;
}
