int main() {
      int i = 0;
      while (i != 1) {
            ++i;
            switch (0) {
                  default: continue;
            }
      }
      for (i = 0; i != 1; ++i) {
            switch (0) {
                  default: continue;
            }
      }
      i = 0;
      do {
            ++i;
            switch (0) {
                  default: continue;
            }
      } while (i != 1);

      for (; i != 1; ++i) {
            continue;
            { ++i; }
      }
}
