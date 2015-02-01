struct {
      int x;
      union {
            int y;
      } u;
} s;

union {
      int x;
      struct {
            int y;
      } s;
} u;

int main(void) {
      return s.u.y + u.s.y;
}
