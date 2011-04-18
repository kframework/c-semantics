/*
 * This is a RANDOMLY GENERATED PROGRAM.
 *
 * Generator: csmith 2.0.0
 * svn version: exported
 * Options:   --check-global -s 1981
 * Seed:      1981
 */

#include "random_runtime.h"


long __undefined;

/* --- Struct/Union Declarations --- */
/* --- GLOBAL VARIABLES --- */
 volatile int16_t g_2 = 0x6240L;/* VOLATILE GLOBAL g_2 */
int32_t g_4 = -1L;
uint64_t g_12 = 0xA1FA147B80BE39E3LL;


/* --- FORWARD DECLARATIONS --- */
int32_t  func_1(void);


/* --- FUNCTIONS --- */
/* ------------------------------------------ */
/* 
 * reads : g_2 g_4
 * writes: g_4 g_12
 */
int32_t  func_1(void)
{ /* block id: 0 */
    int32_t *l_3 = &g_4;
    uint64_t l_11 = 1L;
    (*l_3) ^= g_2;
    for (g_4 = 1; (g_4 >= 0); g_4 = safe_add_func_uint16_t_u_u(g_4, 0))
    { /* block id: 4 */
        g_12 &= (safe_rshift_func_int16_t_s_s((safe_rshift_func_int8_t_s_s((!g_4), l_11)), -9L));
        return g_2;
    }
    return (*l_3);
}




/* ---------------------------------------- */
int main (int argc, char* argv[])
{
    func_1();
    printf("checksum g_2 = %d\n", g_2);
    printf("checksum g_4 = %d\n", g_4);
    printf("checksum g_12 = %d\n", g_12);
}

/************************ statistics *************************
XXX max struct depth: 0
breakdown:
   depth: 0, occurrence: 5

XXX max expression depth: 0
breakdown:
   depth: 0, occurrence: 4

XXX total number of pointers: 1

XXX times a variable address is taken: 1
XXX times a pointer is dereferenced on RHS: 1
breakdown:
   depth: 1, occurrence: 1
XXX times a pointer is dereferenced on LHS: 1
breakdown:
   depth: 1, occurrence: 1
XXX times a pointer is compared with null: 0
XXX times a pointer is compared with address of another variable: 0
XXX times a pointer is compared with another pointer: 0
XXX times a pointer is qualified to be dereferenced: 2

XXX max dereference level: 1
breakdown:
   level: 0, occurrence: 0
   level: 1, occurrence: 4
XXX number of pointers point to pointers: 0
XXX number of pointers point to scalars: 1
XXX number of pointers point to structs: 0
XXX percent of pointers has null in alias set: 0
XXX average alias set size: 1

XXX times a non-volatile is read: 5
XXX times a non-volatile is write: 4
XXX times a volatile is read: 2
XXX    times read thru a pointer: 0
XXX times a volatile is write: 0
XXX    times written thru a pointer: 0
XXX times a volatile is available for access: 4
XXX percentage of non-volatile access: 81.8

XXX forward jumps: 0
XXX backward jumps: 0

XXX stmts: 9

XXX percentage a fresh-made variable is used: 50
XXX percentage an existing variable is used: 50
********************* end of statistics **********************/

