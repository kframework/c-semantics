// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

volatile struct {
  int x;
} foo;

int main() {
  char *y = (char *)&foo.x;
  return *y;
}
