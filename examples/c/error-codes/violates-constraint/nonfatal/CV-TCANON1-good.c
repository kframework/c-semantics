#include <stdalign.h>

struct {
      alignas(int) char x;
};

int main(void) {
      return 0;
}
