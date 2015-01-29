int main(void) {
      int x = 0;
      x + 1;

      goto l;
      {
l:
            ;
            int y = 0;
            y + 1;
      }

      return 0;
}
