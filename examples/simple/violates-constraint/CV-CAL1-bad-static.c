// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include<stdalign.h>
struct foo;

int main() {
  return alignof(struct foo) - 1;
}
