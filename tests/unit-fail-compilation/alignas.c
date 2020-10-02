#include <stdalign.h>

struct {
      alignas(short) long long int x;
};

int main(void) {
      return 0;
}
