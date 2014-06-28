_Noreturn void f(int x){
      if (x) {
            return;
      } else while (1);
}

int main(void){
      f(1);
      return 0;
}
