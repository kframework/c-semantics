int main(void){
      char (*s)[6];
      s = &"hello";
      (*s)[0] = 'x';
      return 0;
}
