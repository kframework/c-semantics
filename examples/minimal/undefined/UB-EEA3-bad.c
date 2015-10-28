int foo;
int *bar = &foo;

int * restrict x;

int main() {
  int * restrict y = bar;
  x = y;
}
