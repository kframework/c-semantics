// 6.7.4p3
static inline int f(void) { 
      static int x = 1;
      return 0;
}

int main(void) {
      return f();
}
