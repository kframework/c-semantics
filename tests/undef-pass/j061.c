struct s {
      int x;
      union {
            int y;
      };
} s;

union u {
      int x;
      struct {
            int y;
      }
} u;

int main(void) {
      return s.y + u.y;
}
