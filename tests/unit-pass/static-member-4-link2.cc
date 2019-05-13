#include "static-member-4.H"

int test::y = 1;

int main() {
    return *test::x - 1;
}