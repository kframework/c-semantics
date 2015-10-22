void f(int a[static 10]) { }

int main(void) {
      f((void*) 0);
      return 0;
}
