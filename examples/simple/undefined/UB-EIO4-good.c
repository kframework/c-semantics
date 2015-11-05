// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

int main() {
  volatile int x;
  volatile int *y = &x;
  *y = 5;
  return 0;
}
