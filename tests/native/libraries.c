#include<dlfcn.h>
#include<stdio.h>

int main() {
  fputs("foo", stdout);
  dlopen("libc.so.6", RTLD_LAZY);
}
