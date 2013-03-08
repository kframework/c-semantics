/*
 * This is a RANDOMLY GENERATED PROGRAM.
 *
 * Generator: csmith 2.0.0
 * svn version: exported
 * Options:   --check-global -s 621
 * Seed:      621
 */

#include "random_runtime.h"


long __undefined;

/* --- Struct/Union Declarations --- */
/* --- GLOBAL VARIABLES --- */
int32_t g_4 = -7L;
int32_t * volatile g_3 = &g_4;/* VOLATILE GLOBAL g_3 */
int32_t *g_11 = &g_4;
int32_t ** const  volatile g_10 = &g_11;/* VOLATILE GLOBAL g_10 */


/* --- FORWARD DECLARATIONS --- */
uint16_t  func_1(void);
int32_t * func_5(int64_t  p_6, int32_t * p_7);


/* --- FUNCTIONS --- */
/* ------------------------------------------ */
/* 
 * reads : g_3 g_4 g_10
 * writes: g_4 g_11
 */
uint16_t  func_1(void)
{ /* block id: 0 */
    uint8_t l_2 = 9L;
    (*g_3) = l_2;
    (*g_10) = func_5(l_2, 0);
    return l_2;
}


/* ------------------------------------------ */
/* 
 * reads : g_3 g_4
 * writes: g_4
 */
int32_t * func_5(int64_t  p_6, int32_t * p_7)
{ /* block id: 2 */
    uint64_t l_8[5];
    int32_t *l_9 = 0;
    int i;
    for (i = 0; i < 5; i++)
        l_8[i] = 1L;
    l_8[0] |= (*g_3);
    for (g_4 = 0; g_4 < 5; g_4 += 1)
    {
        l_8[g_4] = 0L;
    }
    return l_9;
}




/* ---------------------------------------- */
int main (int argc, char* argv[])
{
    func_1();
    printf("checksum g_4 = %d\n", g_4);
}

/************************ statistics *************************
XXX max struct depth: 0
breakdown:
   depth: 0, occurrence: 7

XXX max expression depth: 0
breakdown:
   depth: 0, occurrence: 5

XXX total number of pointers: 5

XXX times a variable address is taken: 2
XXX times a pointer is dereferenced on RHS: 1
breakdown:
   depth: 1, occurrence: 1
XXX times a pointer is dereferenced on LHS: 2
breakdown:
   depth: 1, occurrence: 2
XXX times a pointer is compared with null: 0
XXX times a pointer is compared with address of another variable: 0
XXX times a pointer is compared with another pointer: 0
XXX times a pointer is qualified to be dereferenced: 3

XXX max dereference level: 1
breakdown:
   level: 0, occurrence: 0
   level: 1, occurrence: 6
XXX number of pointers point to pointers: 1
XXX number of pointers point to scalars: 4
XXX number of pointers point to structs: 0
XXX percent of pointers has null in alias set: 60
XXX average alias set size: 1.2

XXX times a non-volatile is read: 5
XXX times a non-volatile is write: 3
XXX times a volatile is read: 1
XXX    times read thru a pointer: 0
XXX times a volatile is write: 2
XXX    times written thru a pointer: 0
XXX times a volatile is available for access: 2
XXX percentage of non-volatile access: 72.7

XXX forward jumps: 0
XXX backward jumps: 0

XXX stmts: 8

XXX percentage a fresh-made variable is used: 50
XXX percentage an existing variable is used: 50
********************* end of statistics **********************/

