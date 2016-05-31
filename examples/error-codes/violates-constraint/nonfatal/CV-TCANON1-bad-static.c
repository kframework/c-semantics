#include <stdalign.h>

struct {
      alignas(int) long long int x;
};

int main(void) {
      return 0;
}
