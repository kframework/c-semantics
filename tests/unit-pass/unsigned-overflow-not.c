#include <limits.h>

int main() {
    unsigned int value = 0x0300U;
    unsigned int tmp;
    tmp = ~0x0300U;
    tmp = ~value;
}
