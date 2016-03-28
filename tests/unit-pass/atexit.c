#include<stdlib.h>
#include<stdio.h>

void bar() {}

void foo() {
  printf("%s", "Hello World!");
}

int main() {
  atexit(foo);
}
