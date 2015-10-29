// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

volatile struct {
  int x;
} foo;

int main() {
  int *y = (int *)&foo.x;
  return *y;
}
