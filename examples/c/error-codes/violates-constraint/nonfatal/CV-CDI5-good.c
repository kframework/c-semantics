struct {
      struct {
            int v;
      };
} s = { .v = 2 };

int main(void) {
      return s.v != 2;
}

