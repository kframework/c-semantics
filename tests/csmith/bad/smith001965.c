/*
 * This is a RANDOMLY GENERATED PROGRAM.
 *
 * Generator: csmith 2.0.0
 * svn version: exported
 * Options:   --check-global -s 1965
 * Seed:      1965
 */

#include "random_runtime.h"


long __undefined;

/* --- Struct/Union Declarations --- */
struct S0 {
    const uint64_t  f0;
   int32_t  f1;
   int32_t  f2;
    const uint32_t  f3;
};

/* --- GLOBAL VARIABLES --- */
struct S0 g_3 = {0xBF34FDA0E60F951FLL,1L,0L,0x876942A1L};
int32_t g_21[7] = {-10L, -10L, -10L, -10L, -10L, -10L, -10L};
struct S0 *g_23 = &g_3;
struct S0 **g_22 = &g_23;
int32_t * volatile g_24 = &g_21[2];/* VOLATILE GLOBAL g_24 */


/* --- FORWARD DECLARATIONS --- */
uint16_t  func_1(void);
int32_t  func_5(uint32_t  p_6, uint16_t  p_7, int32_t  p_8, struct S0 ** p_9, int16_t  p_10);
struct S0 ** func_13(struct S0 * p_14);


/* --- FUNCTIONS --- */
/* ------------------------------------------ */
/* 
 * reads : g_3.f1 g_22 g_3.f3 g_24 g_3.f0
 * writes: g_3.f1 g_21
 */
uint16_t  func_1(void)
{ /* block id: 0 */
    struct S0 *l_2[3][9][3];
    struct S0 **l_4 = &l_2[0][8][1];
    int32_t l_11[4];
    int8_t l_12 = 1L;
    int i, j, k;
    for (i = 0; i < 3; i++)
    {
        for (j = 0; j < 9; j++)
        {
            for (k = 0; k < 3; k++)
                l_2[i][j][k] = &g_3;
        }
    }
    for (i = 0; i < 4; i++)
        l_11[i] = 0x4896E6A3L;
    (*l_4) = l_2[0][8][1];
    (*g_24) = func_5(l_11[3], -5L, l_12, func_13(0), l_12);
    return g_3.f0;
}


/* ------------------------------------------ */
/* 
 * reads : g_3.f3
 * writes:
 */
int32_t  func_5(uint32_t  p_6, uint16_t  p_7, int32_t  p_8, struct S0 ** p_9, int16_t  p_10)
{ /* block id: 2 */
    return g_3.f3;
}


/* ------------------------------------------ */
/* 
 * reads : g_3.f1 g_22
 * writes: g_3.f1 g_21
 */
struct S0 ** func_13(struct S0 * p_14)
{ /* block id: 4 */
     const uint8_t l_15 = 0x5BL;
    int32_t *l_16 = 0;
    int32_t *l_17 = &g_3.f1;
    int32_t *l_18 = 0;
    int32_t *l_19 = 0;
    int32_t *l_20 = &g_21[2];
    (*l_17) ^= l_15;
    (*l_20) |= g_3.f1;
    return g_22;
}




/* ---------------------------------------- */
int main (int argc, char* argv[])
{
    int i;
    func_1();
    printf("checksum g_3.f0 = %d\n", g_3.f0);
    printf("checksum g_3.f1 = %d\n", g_3.f1);
    printf("checksum g_3.f2 = %d\n", g_3.f2);
    printf("checksum g_3.f3 = %d\n", g_3.f3);
    printf("checksum g_21[0] = %d\n", g_21[0]);
    printf("checksum g_21[1] = %d\n", g_21[1]);
    printf("checksum g_21[2] = %d\n", g_21[2]);
    printf("checksum g_21[3] = %d\n", g_21[3]);
    printf("checksum g_21[4] = %d\n", g_21[4]);
    printf("checksum g_21[5] = %d\n", g_21[5]);
    printf("checksum g_21[6] = %d\n", g_21[6]);
    printf("checksum g_21[2] = %d\n", g_21[2]);
}

/************************ statistics *************************
XXX max struct depth: 1
breakdown:
   depth: 0, occurrence: 14
   depth: 1, occurrence: 1

XXX max expression depth: 0
breakdown:
   depth: 0, occurrence: 7

XXX total number of pointers: 11

XXX times a variable address is taken: 3
XXX times a pointer is dereferenced on RHS: 0
breakdown:
XXX times a pointer is dereferenced on LHS: 4
breakdown:
   depth: 1, occurrence: 4
XXX times a pointer is compared with null: 0
XXX times a pointer is compared with address of another variable: 0
XXX times a pointer is compared with another pointer: 0
XXX times a pointer is qualified to be dereferenced: 6

XXX max dereference level: 1
breakdown:
   level: 0, occurrence: 0
   level: 1, occurrence: 11
XXX number of pointers point to pointers: 2
XXX number of pointers point to scalars: 6
XXX number of pointers point to structs: 3
XXX percent of pointers has null in alias set: 36.4
XXX average alias set size: 1

XXX times a non-volatile is read: 9
XXX times a non-volatile is write: 7
XXX times a volatile is read: 0
XXX    times read thru a pointer: 0
XXX times a volatile is write: 1
XXX    times written thru a pointer: 0
XXX times a volatile is available for access: 0
XXX percentage of non-volatile access: 94.1

XXX forward jumps: 0
XXX backward jumps: 0

XXX stmts: 10

XXX percentage a fresh-made variable is used: 55.6
XXX percentage an existing variable is used: 44.4
********************* end of statistics **********************/

