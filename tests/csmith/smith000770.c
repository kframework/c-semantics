/*
 * This is a RANDOMLY GENERATED PROGRAM.
 *
 * Generator: csmith 2.0.0
 * svn version: exported
 * Options:   --check-global -s 770
 * Seed:      770
 */

#include "random_runtime.h"


long __undefined;

/* --- Struct/Union Declarations --- */
/* --- GLOBAL VARIABLES --- */
 volatile uint32_t g_5 = 0L;/* VOLATILE GLOBAL g_5 */
 volatile int32_t g_8 = 0x770A77C8L;/* VOLATILE GLOBAL g_8 */
 volatile int32_t * volatile g_7 = &g_8;/* VOLATILE GLOBAL g_7 */


/* --- FORWARD DECLARATIONS --- */
int32_t  func_1(void);
int32_t * const  func_2(int32_t * p_3, int8_t  p_4);


/* --- FUNCTIONS --- */
/* ------------------------------------------ */
/* 
 * reads : g_7 g_8
 * writes: g_7 g_5
 */
int32_t  func_1(void)
{ /* block id: 0 */
    int32_t *l_6[2][7];
     volatile int32_t * volatile *l_9 = &g_7;
    uint8_t l_12[7][3][1];
    int i, j, k;
    for (i = 0; i < 2; i++)
    {
        for (j = 0; j < 7; j++)
            l_6[i][j] = 0;
    }
    for (i = 0; i < 7; i++)
    {
        for (j = 0; j < 3; j++)
        {
            for (k = 0; k < 1; k++)
                l_12[i][j][k] = 0xC7L;
        }
    }
    (*l_9) = g_7;
    for (g_5 = 19; (g_5 <= 3); g_5 = safe_add_func_int16_t_s_s(g_5, 1))
    { /* block id: 7 */
        return (*g_7);
    }
    return l_12[0][2][0];
}


/* ------------------------------------------ */
/* 
 * reads : g_5
 * writes:
 */
int32_t * const  func_2(int32_t * p_3, int8_t  p_4)
{ /* block id: 1 */
    (*p_3) = g_5;
    return p_3;
}




/* ---------------------------------------- */
int main (int argc, char* argv[])
{
    func_1();
    printf("checksum g_5 = %d\n", g_5);
    printf("checksum g_8 = %d\n", g_8);
}

/************************ statistics *************************
XXX max struct depth: 0
breakdown:
   depth: 0, occurrence: 6

XXX max expression depth: 0
breakdown:
   depth: 0, occurrence: 5

XXX total number of pointers: 4

XXX times a variable address is taken: 1
XXX times a pointer is dereferenced on RHS: 1
breakdown:
   depth: 1, occurrence: 1
XXX times a pointer is dereferenced on LHS: 2
breakdown:
   depth: 1, occurrence: 2
XXX times a pointer is compared with null: 0
XXX times a pointer is compared with address of another variable: 0
XXX times a pointer is compared with another pointer: 0
XXX times a pointer is qualified to be dereferenced: 4

XXX max dereference level: 1
breakdown:
   level: 0, occurrence: 0
   level: 1, occurrence: 5
XXX number of pointers point to pointers: 1
XXX number of pointers point to scalars: 3
XXX number of pointers point to structs: 0
XXX percent of pointers has null in alias set: 25
XXX average alias set size: 1

XXX times a non-volatile is read: 3
XXX times a non-volatile is write: 3
XXX times a volatile is read: 6
XXX    times read thru a pointer: 1
XXX times a volatile is write: 2
XXX    times written thru a pointer: 1
XXX times a volatile is available for access: 5
XXX percentage of non-volatile access: 42.9

XXX forward jumps: 0
XXX backward jumps: 0

XXX stmts: 11

XXX percentage a fresh-made variable is used: 50
XXX percentage an existing variable is used: 50
********************* end of statistics **********************/

