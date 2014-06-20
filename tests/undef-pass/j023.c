void f() { }
int g() { return 0; }

int main(void) {
      f();
      g();
      (void) f();

      (void) 1;

      int x;
      (void)(x = 5);

      (void)(int) 5;

      return 0;
}
