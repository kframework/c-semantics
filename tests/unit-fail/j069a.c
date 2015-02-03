int f(int * restrict p, int * restrict q) {
      p = q;
      return 0;
}

int main(void){
      int p = 5;
      int q = 6;
      return f(&p, &q);
}
