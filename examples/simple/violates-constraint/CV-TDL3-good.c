// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

_Alignas(1) int x = 42;

int main(void) {
      extern _Alignas(1) int x;
      return 0;
}
