#include<stdalign.h>
struct foo;

int main() {
  return alignof(struct foo) - 1;
}
