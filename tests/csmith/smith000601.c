/*
 * This is a RANDOMLY GENERATED PROGRAM.
 *
 * Generator: csmith 2.0.0
 * svn version: exported
 * Options:   --check-global -s 601
 * Seed:      601
 */

#include "random_runtime.h"


long __undefined;

/* --- Struct/Union Declarations --- */
struct S2 {
   int32_t  f0;
   int32_t  f1;
};

/* --- GLOBAL VARIABLES --- */
 volatile int32_t g_3 = -9L;/* VOLATILE GLOBAL g_3 */
int32_t g_6 = 1L;
int32_t * volatile g_5 = &g_6;/* VOLATILE GLOBAL g_5 */
int32_t g_10 = 0x2DB8E964L;
struct S2 g_16 = {0x64A11600L,0x5493E623L};


/* --- FORWARD DECLARATIONS --- */
int32_t  func_1(void);
int32_t * func_11(int32_t * const  p_12, struct S2  p_13, int32_t * const  p_14);


/* --- FUNCTIONS --- */
/* ------------------------------------------ */
/* 
 * reads : g_5 g_6 g_16
 * writes: g_3 g_6 g_10
 */
int32_t  func_1(void)
{ /* block id: 0 */
    int32_t l_2[4];
    int32_t *l_9 = &g_10;
    int32_t **l_17 = &l_9;
    int i;
    for (i = 0; i < 4; i++)
        l_2[i] = 9L;
    for (g_3 = 1; g_3 < 4; g_3 += 4)
    { /* block id: 1 */
        uint16_t l_4[6];
        int i;
        for (i = 0; i < 6; i++)
            l_4[i] = 0xD8CFL;
        (*g_5) ^= l_4[1];
    }
    (*l_9) &= (safe_mod_func_int16_t_s_s((*g_5), g_6));
    (*l_17) = func_11(&g_10, g_16, 0);
    return (**l_17);
}


/* ------------------------------------------ */
/* 
 * reads :
 * writes:
 */
int32_t * func_11(int32_t * const  p_12, struct S2  p_13, int32_t * const  p_14)
{ /* block id: 5 */
    int32_t *l_15 = &g_6;
    return l_15;
}




/* ---------------------------------------- */
int main (int argc, char* argv[])
{
    func_1();
    printf("checksum g_3 = %d\n", g_3);
    printf("checksum g_6 = %d\n", g_6);
    printf("checksum g_10 = %d\n", g_10);
    printf("checksum g_16.f0 = %d\n", g_16.f0);
    printf("checksum g_16.f1 = %d\n", g_16.f1);
}

/************************ statistics *************************
XXX max struct depth: 1
breakdown:
   depth: 0, occurrence: 8
   depth: 1, occurrence: 1

XXX max expression depth: 0
breakdown:
   depth: 0, occurrence: 5

XXX total number of pointers: 5

XXX times a variable address is taken: 3
XXX times a pointer is dereferenced on RHS: 2
breakdown:
   depth: 1, occurrence: 1
   depth: 2, occurrence: 1
XXX times a pointer is dereferenced on LHS: 3
breakdown:
   depth: 1, occurrence: 3
XXX times a pointer is compared with null: 0
XXX times a pointer is compared with address of another variable: 0
XXX times a pointer is compared with another pointer: 0
XXX times a pointer is qualified to be dereferenced: 5

XXX max dereference level: 2
breakdown:
   level: 0, occurrence: 0
   level: 1, occurrence: 7
   level: 2, occurrence: 2
XXX number of pointers point to pointers: 1
XXX number of pointers point to scalars: 4
XXX number of pointers point to structs: 0
XXX percent of pointers has null in alias set: 20
XXX average alias set size: 1.2

XXX times a non-volatile is read: 8
XXX times a non-volatile is write: 5
XXX times a volatile is read: 1
XXX    times read thru a pointer: 0
XXX times a volatile is write: 1
XXX    times written thru a pointer: 0
XXX times a volatile is available for access: 1
XXX percentage of non-volatile access: 86.7

XXX forward jumps: 0
XXX backward jumps: 0

XXX stmts: 9

XXX percentage a fresh-made variable is used: 42.9
XXX percentage an existing variable is used: 57.1
********************* end of statistics **********************/

