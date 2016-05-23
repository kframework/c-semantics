// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

union {
  int x;
  float y;
} foo;

int main() {
  foo.y = 1.0;
  int x = foo.x;
  return 0;
}
