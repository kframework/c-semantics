// this example is loosely based on an example in sentence 1509 in http://www.knosof.co.uk/cbook/cbook.html
int g(int * p) {
      *p = 10;
      return 0;
}

int f(const int * restrict p) {
      g((int*)p);
      return *p;
}

int main(void){
      int x = 5;
      return f(&x) == 5;
}
