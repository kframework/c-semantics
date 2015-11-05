// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

volatile struct {
  int x;
} foo;

int main() {
  volatile int *y = &foo.x;
  return *y;
}
