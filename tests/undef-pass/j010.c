int y;
int* f(void) {
      int x;
      return &y;
}

int main(void){
      int* p = 0;
      {
            int x;
            p = &x;
      }

      p = f();

      int i = 0;
      while (i < 10){
            int x = 2;
            i++;
            p = &x;
      }
      return 0;
}
