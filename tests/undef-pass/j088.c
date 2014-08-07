int f() {
      return 0;
}

int g() { }

int main(void) {
      f();
      f() + 0;
      // g(); // This probably shouldn't count as a use.
      return f();
}
