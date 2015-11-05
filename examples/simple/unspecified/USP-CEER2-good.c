// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

union {
  int x;
  float y;
} foo;

int main() {
  foo.x = 1;
  char x = *((char *)&foo.y);
  return 0;
}
