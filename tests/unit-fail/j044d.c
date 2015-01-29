union str {int *x;};

int main(void) {
      int x = 5;
      int *p = &x;
      (union str)p;
}
