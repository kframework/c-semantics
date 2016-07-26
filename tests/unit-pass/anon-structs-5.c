#include <stdlib.h>
struct s { struct { int x; }; } foo;
struct s bar() {
  foo.x = 7;
  return foo;
}
int main() {
  if (bar().x != 7) exit(EXIT_FAILURE);
  return 0;
}
