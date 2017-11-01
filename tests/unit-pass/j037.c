int main(void) {
      float x = 5;
      float* p = (float*)&x;
      *p;

      int y = 5;
      struct { int x; } s = { 0 };
      union { int x; float y; } u = { 0 };
      *((int*)&y);
      *((int*)&s);
      *((union {int x; float y; }*)&u);

      return 0;
}
