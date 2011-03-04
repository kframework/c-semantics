/*
 * This is a RANDOMLY GENERATED PROGRAM.
 *
 * Generator: csmith 2.0.0
 * svn version: exported
 * Options:   --check-global -s 45
 * Seed:      45
 */

#include "random_runtime.h"


long __undefined;

/* --- Struct/Union Declarations --- */
/* --- GLOBAL VARIABLES --- */
int32_t g_10 = 0x4210E164L;
int32_t * volatile g_9 = &g_10;/* VOLATILE GLOBAL g_9 */
int32_t *g_15[8] = {0, 0, 0, 0, 0, 0, 0, 0};
int32_t ** volatile g_14 = &g_15[6];/* VOLATILE GLOBAL g_14 */


/* --- FORWARD DECLARATIONS --- */
uint16_t  func_1(void);
int32_t * func_2(int32_t * p_3, int32_t * p_4, uint16_t  p_5);


/* --- FUNCTIONS --- */
/* ------------------------------------------ */
/* 
 * reads : g_9 g_10 g_14
 * writes: g_15 g_10
 */
uint16_t  func_1(void)
{ /* block id: 0 */
    int32_t *l_13 = 0;
    int32_t l_16[2][1];
    int32_t *l_17 = &g_10;
    int i, j;
    for (i = 0; i < 2; i++)
    {
        for (j = 0; j < 1; j++)
            l_16[i][j] = 0x263D1880L;
    }
    (*g_14) = func_2(&g_10, l_13, ((*g_9) >= g_10));
    (*l_17) = l_16[0][0];
    return g_10;
}


/* ------------------------------------------ */
/* 
 * reads : g_9 g_10
 * writes:
 */
int32_t * func_2(int32_t * p_3, int32_t * p_4, uint16_t  p_5)
{ /* block id: 1 */
    int32_t * volatile l_11 = &g_10;/* VOLATILE GLOBAL l_11 */
    int32_t *l_12 = &g_10;
    for (p_5 = 2; (p_5 == -16); p_5 = safe_sub_func_int16_t_s_s(p_5, 1))
    { /* block id: 4 */
        int8_t l_8 = 0xA1L;
        if (l_8)
            break;
        l_11 = g_9;
        if ((*p_3))
            break;
    }
    return l_12;
}




/* ---------------------------------------- */
int main (int argc, char* argv[])
{
    int i;
    func_1();
    printf("checksum g_10 = %d\n", g_10);
}

/************************ statistics *************************
XXX max struct depth: 0
breakdown:
   depth: 0, occurrence: 10

XXX max expression depth: 0
breakdown:
   depth: 0, occurrence: 5

XXX total number of pointers: 9

XXX times a variable address is taken: 3
XXX times a pointer is dereferenced on RHS: 2
breakdown:
   depth: 1, occurrence: 2
XXX times a pointer is dereferenced on LHS: 2
breakdown:
   depth: 1, occurrence: 2
XXX times a pointer is compared with null: 0
XXX times a pointer is compared with address of another variable: 0
XXX times a pointer is compared with another pointer: 0
XXX times a pointer is qualified to be dereferenced: 9

XXX max dereference level: 2
breakdown:
   level: 0, occurrence: 0
   level: 1, occurrence: 7
   level: 2, occurrence: 1
XXX number of pointers point to pointers: 1
XXX number of pointers point to scalars: 8
XXX number of pointers point to structs: 0
XXX percent of pointers has null in alias set: 33.3
XXX average alias set size: 1.11

XXX times a non-volatile is read: 10
XXX times a non-volatile is write: 4
XXX times a volatile is read: 2
XXX    times read thru a pointer: 0
XXX times a volatile is write: 2
XXX    times written thru a pointer: 0
XXX times a volatile is available for access: 5
XXX percentage of non-volatile access: 77.8

XXX forward jumps: 0
XXX backward jumps: 0

XXX stmts: 13

XXX percentage a fresh-made variable is used: 42.9
XXX percentage an existing variable is used: 57.1
********************* end of statistics **********************/

