// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

#include<stdalign.h>
struct foo {
  char x;
};

int main() {
  return alignof(struct foo) - 1;
}
