// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

#include<stdalign.h>
struct foo {
  char x;
};

int main() {
  return alignof(struct foo) - 1;
}
