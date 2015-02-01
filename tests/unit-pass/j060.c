int main(void){
      extern int f();
      int g();
      return f() + g();
}

int f(void) {
      return 0;
}

int g(void) {
      return 0;
}
