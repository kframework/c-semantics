int foo;
int *bar = &foo;

int * restrict x;

int main() {
  int *y = bar;
  x = y;
}
