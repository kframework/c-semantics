#include <stdint.h>
#include <stddef.h>
#include <stdio.h>

struct A
{
    uint32_t *a;
    uint16_t b;
};

_Static_assert(sizeof(struct A) == 16, "");

#pragma pack(4)
struct B
{
    uint32_t *a;
    uint16_t b;
};

_Static_assert(sizeof(struct B) == 12, "");

struct C
{
    uint32_t *a;
    uint16_t b;
};

_Static_assert(sizeof(struct C) == 12, "");


#pragma pack()
struct D
{
    uint32_t *a;
    uint16_t b;
};

_Static_assert(sizeof(struct D) == 16, "");

#pragma pack(2)
struct E
{
    uint8_t a;
    uint32_t b;
};

_Static_assert(offsetof(struct E, b) == 2, "");
_Static_assert(sizeof(struct E) == 6, "");

int main() {
  return 0;
}
