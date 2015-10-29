// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

union {
  int x;
  float y;
} foo;

int main() {
  foo.x = 1;
  float x = foo.y;
  return 0;
}
