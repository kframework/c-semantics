#include<stdio.h>
#include<stdarg.h>

int func(char *buf, size_t len, char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int res = vsnprintf(buf, len, fmt, ap);
  va_end(ap);
  return res;
}

int main() {
  char buf[13];
  
  func(buf, 13, "%s", "Hello World!\n");
  printf("%s", buf);
}
