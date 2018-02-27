int foo();
void bar(void);

int main(void) {
      foo(5);
      ((int (*)(int))bar)(5);
      return 0;
}

int foo() {
      return 0;
}

void bar(void) { }
