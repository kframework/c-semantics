extern inline int f(void) { 
      static int x = 1;
      return 0;
}

int main(void) {
      return f();
}
