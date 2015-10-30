// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

_Alignas(1) int x = 42;

int main(void) {
      extern _Alignas(4) int x;
      return 0;
}
