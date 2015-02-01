int x = 10;
int* a;
float* b;

int main(void) {
      a = &x;
      b = (float*)a;
      *b;
      return 0;
}
