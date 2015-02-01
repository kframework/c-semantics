int f(int x, int y) {
      return x;
}

int g(double x) {
      return (int) x;
}

int main(void) {
      ((int (*)())f)(0, 0);

      ((int (*)())g)(0.0);

      int bar();
      bar(5.0);

      int baz();
      baz((char)5);

      int bah();
      bah(5);

      return 0;
}

int bar(double a){
      return 0;
}

int baz(int x){
      return 0;
}

int bah(int x){
      return x;
}
