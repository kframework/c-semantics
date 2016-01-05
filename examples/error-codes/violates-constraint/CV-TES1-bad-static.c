// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <stdio.h>
void func() {
  printf("Function Definition\n");
}

int main() {
  //Not allowed by C11.
  size_t a = sizeof(func);

  func();

}
