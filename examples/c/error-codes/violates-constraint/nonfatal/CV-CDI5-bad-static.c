struct {
      struct {
            int v;
      };
} s = { { .v = 2, 3 } };

int main(void) {
      return s.v;
}

