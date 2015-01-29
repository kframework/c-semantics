int main(void) {
      const int x = 0;
      unsigned char* p = (unsigned char*)&x;
      *p = 5;
      return 0;
}
