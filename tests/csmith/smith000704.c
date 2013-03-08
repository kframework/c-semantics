/*
 * This is a RANDOMLY GENERATED PROGRAM.
 *
 * Generator: csmith 2.0.0
 * svn version: exported
 * Options:   --check-global -s 704
 * Seed:      704
 */

#include "random_runtime.h"


long __undefined;

/* --- Struct/Union Declarations --- */
/* --- GLOBAL VARIABLES --- */
 volatile uint16_t g_5 = -1L;/* VOLATILE GLOBAL g_5 */
int16_t g_6 = 1L;


/* --- FORWARD DECLARATIONS --- */
uint8_t  func_1(void);


/* --- FUNCTIONS --- */
/* ------------------------------------------ */
/* 
 * reads : g_5 g_6
 * writes: g_5
 */
uint8_t  func_1(void)
{ /* block id: 0 */
    int32_t l_4 = 1L;
lbl_9:
    l_4 = (safe_mul_func_int16_t_s_s(l_4, ((l_4 & g_5) ^ g_6)));
    for (g_5 = 5; (g_5 != 5); g_5 = safe_sub_func_int8_t_s_s(g_5, 7))
    { /* block id: 4 */
        int32_t *l_10 = 0;
        int32_t *l_11 = &l_4;
        if (g_6)
            goto lbl_9;
        (*l_11) |= 0xA1245C81L;
    }
    return g_6;
}




/* ---------------------------------------- */
int main (int argc, char* argv[])
{
    func_1();
    printf("checksum g_5 = %d\n", g_5);
    printf("checksum g_6 = %d\n", g_6);
}

/************************ statistics *************************
XXX max struct depth: 0
breakdown:
   depth: 0, occurrence: 5

XXX max expression depth: 0
breakdown:
   depth: 0, occurrence: 3

XXX total number of pointers: 2

XXX times a variable address is taken: 0
XXX times a pointer is dereferenced on RHS: 0
breakdown:
XXX times a pointer is dereferenced on LHS: 1
breakdown:
   depth: 1, occurrence: 1
XXX times a pointer is compared with null: 0
XXX times a pointer is compared with address of another variable: 0
XXX times a pointer is compared with another pointer: 0
XXX times a pointer is qualified to be dereferenced: 0

XXX max dereference level: 1
breakdown:
   level: 0, occurrence: 0
   level: 1, occurrence: 2
XXX number of pointers point to pointers: 0
XXX number of pointers point to scalars: 2
XXX number of pointers point to structs: 0
XXX percent of pointers has null in alias set: 50
XXX average alias set size: 1

XXX times a non-volatile is read: 4
XXX times a non-volatile is write: 3
XXX times a volatile is read: 2
XXX    times read thru a pointer: 0
XXX times a volatile is write: 1
XXX    times written thru a pointer: 0
XXX times a volatile is available for access: 2
XXX percentage of non-volatile access: 70

XXX forward jumps: 0
XXX backward jumps: 1

XXX stmts: 9

XXX percentage a fresh-made variable is used: 50
XXX percentage an existing variable is used: 50
********************* end of statistics **********************/

