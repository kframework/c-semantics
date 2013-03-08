/*
 * This is a RANDOMLY GENERATED PROGRAM.
 *
 * Generator: csmith 2.0.0
 * svn version: exported
 * Options:   --check-global -s 431
 * Seed:      431
 */

#include "random_runtime.h"


long __undefined;

/* --- Struct/Union Declarations --- */
/* --- GLOBAL VARIABLES --- */
int32_t g_5 = 4L;
int32_t * volatile g_4 = &g_5;/* VOLATILE GLOBAL g_4 */


/* --- FORWARD DECLARATIONS --- */
int64_t  func_1(void);


/* --- FUNCTIONS --- */
/* ------------------------------------------ */
/* 
 * reads : g_4 g_5
 * writes: g_5
 */
int64_t  func_1(void)
{ /* block id: 0 */
    int32_t * volatile *l_7 = &g_4;
    int32_t * volatile **l_6 = &l_7;
    (*g_4) &= (safe_lshift_func_int16_t_s_u(0L, 0x5C184C50L));
    (*l_6) = &g_4;
    (***l_6) = (safe_add_func_uint16_t_u_u((***l_6), g_5));
    return (***l_6);
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
   depth: 0, occurrence: 4

XXX max expression depth: 0
breakdown:
   depth: 0, occurrence: 4

XXX total number of pointers: 3

XXX times a variable address is taken: 3
XXX times a pointer is dereferenced on RHS: 2
breakdown:
   depth: 1, occurrence: 0
   depth: 2, occurrence: 0
   depth: 3, occurrence: 2
XXX times a pointer is dereferenced on LHS: 3
breakdown:
   depth: 1, occurrence: 2
   depth: 2, occurrence: 0
   depth: 3, occurrence: 1
XXX times a pointer is compared with null: 0
XXX times a pointer is compared with address of another variable: 0
XXX times a pointer is compared with another pointer: 0
XXX times a pointer is qualified to be dereferenced: 5

XXX max dereference level: 3
breakdown:
   level: 0, occurrence: 0
   level: 1, occurrence: 4
   level: 2, occurrence: 1
   level: 3, occurrence: 5
XXX number of pointers point to pointers: 2
XXX number of pointers point to scalars: 1
XXX number of pointers point to structs: 0
XXX percent of pointers has null in alias set: 0
XXX average alias set size: 1

XXX times a non-volatile is read: 8
XXX times a non-volatile is write: 6
XXX times a volatile is read: 2
XXX    times read thru a pointer: 2
XXX times a volatile is write: 2
XXX    times written thru a pointer: 1
XXX times a volatile is available for access: 2
XXX percentage of non-volatile access: 77.8

XXX forward jumps: 0
XXX backward jumps: 0

XXX stmts: 5

XXX percentage a fresh-made variable is used: 0
XXX percentage an existing variable is used: 100
********************* end of statistics **********************/

