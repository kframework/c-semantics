int x;

int main(void) {
      static int x = 1;
      extern int x;
      return x;
}
