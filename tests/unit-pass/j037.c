int main(void) {
      float x = 5;
      float* p = (float*)&x;
      *p;

      int y = 5;
      *((int*)&y);
      *((struct { int x; }*) &y);
      *((union { float x; int y; }*) &y);

      return 0;
}
