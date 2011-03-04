/*
 * This is a RANDOMLY GENERATED PROGRAM.
 *
 * Generator: csmith 2.0.0
 * svn version: exported
 * Options:   --check-global -s 220
 * Seed:      220
 */

#include "random_runtime.h"


long __undefined;

/* --- Struct/Union Declarations --- */
/* --- GLOBAL VARIABLES --- */
int32_t g_5 = 7L;
int32_t ** volatile g_6 = 0;/* VOLATILE GLOBAL g_6 */


/* --- FORWARD DECLARATIONS --- */
uint32_t  func_1(void);
int32_t * func_2(int16_t  p_3);


/* --- FUNCTIONS --- */
/* ------------------------------------------ */
/* 
 * reads : g_5
 * writes:
 */
uint32_t  func_1(void)
{ /* block id: 0 */
    int32_t *l_8[2][7];
    int32_t **l_7 = &l_8[0][6];
    int i, j;
    for (i = 0; i < 2; i++)
    {
        for (j = 0; j < 7; j++)
            l_8[i][j] = &g_5;
    }
    (*l_7) = func_2(g_5);
    return g_5;
}


/* ------------------------------------------ */
/* 
 * reads :
 * writes:
 */
int32_t * func_2(int16_t  p_3)
{ /* block id: 1 */
    int32_t *l_4 = &g_5;
    return l_4;
}




/* ---------------------------------------- */
int main (int argc, char* argv[])
{
    func_1();
    printf("checksum g_5 = %d\n", g_5);
}

/************************ statistics *************************
XXX max struct depth: 0
breakdown:
   depth: 0, occurrence: 5

XXX max expression depth: 0
breakdown:
   depth: 0, occurrence: 3

XXX total number of pointers: 3

XXX times a variable address is taken: 2
XXX times a pointer is dereferenced on RHS: 0
breakdown:
XXX times a pointer is dereferenced on LHS: 1
breakdown:
   depth: 1, occurrence: 1
XXX times a pointer is compared with null: 0
XXX times a pointer is compared with address of another variable: 0
XXX times a pointer is compared with another pointer: 0
XXX times a pointer is qualified to be dereferenced: 1

XXX max dereference level: 1
breakdown:
   level: 0, occurrence: 0
   level: 1, occurrence: 2
XXX number of pointers point to pointers: 2
XXX number of pointers point to scalars: 1
XXX number of pointers point to structs: 0
XXX percent of pointers has null in alias set: 33.3
XXX average alias set size: 1

XXX times a non-volatile is read: 4
XXX times a non-volatile is write: 2
XXX times a volatile is read: 0
XXX    times read thru a pointer: 0
XXX times a volatile is write: 0
XXX    times written thru a pointer: 0
XXX times a volatile is available for access: 1
XXX percentage of non-volatile access: 100

XXX forward jumps: 0
XXX backward jumps: 0

XXX stmts: 5

XXX percentage a fresh-made variable is used: 25
XXX percentage an existing variable is used: 75
********************* end of statistics **********************/

