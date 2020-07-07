#include <limits.h>

int main() {
    unsigned int value = 1u;
    unsigned int tmp;
    tmp = UINT_MAX + 1u;
    tmp = UINT_MAX + value;
}
