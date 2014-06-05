int main(void) {
      float x = 5;
      float* p = (float*)&x;
      *p;

      int y = 5;
      *((int*)&y);

      return 0;
}
