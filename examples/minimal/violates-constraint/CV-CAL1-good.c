#include<stdalign.h>
struct foo {
  char x;
};

int main() {
  return alignof(struct foo) - 1;
}
