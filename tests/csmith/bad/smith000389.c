/*
 * This is a RANDOMLY GENERATED PROGRAM.
 *
 * Generator: csmith 2.0.0
 * svn version: exported
 * Options:   --check-global -s 389
 * Seed:      389
 */

#include "random_runtime.h"


long __undefined;

/* --- Struct/Union Declarations --- */
/* --- GLOBAL VARIABLES --- */
 volatile uint64_t g_4 = 0xBF0B96CA2CB51DBALL;/* VOLATILE GLOBAL g_4 */
uint16_t g_5 = 0L;


/* --- FORWARD DECLARATIONS --- */
int32_t  func_1(void);


/* --- FUNCTIONS --- */
/* ------------------------------------------ */
/* 
 * reads : g_4 g_5
 * writes: g_5
 */
int32_t  func_1(void)
{ /* block id: 0 */
    int8_t l_6 = 9L;
    int32_t l_12 = 0x20452A26L;
    l_6 ^= (safe_rshift_func_int16_t_s_u((g_4 != g_5), 0xE6DA5043L));
    for (g_5 = 3; (g_5 <= -16); g_5 = safe_add_func_int16_t_s_s(g_5, 1))
    { /* block id: 4 */
         const uint16_t l_11 = -1L;
        if (g_5)
            break;
        l_12 &= (g_5 || (safe_lshift_func_uint8_t_u_u(l_11, g_4)));
    }
    return l_12;
}




/* ---------------------------------------- */
int main (int argc, char* argv[])
{
    func_1();
    printf("checksum g_4 = %d\n", g_4);
    printf("checksum g_5 = %d\n", g_5);
}

/************************ statistics *************************
XXX max struct depth: 0
breakdown:
   depth: 0, occurrence: 5

XXX max expression depth: 0
breakdown:
   depth: 0, occurrence: 3

XXX total number of pointers: 0

XXX times a non-volatile is read: 6
XXX times a non-volatile is write: 3
XXX times a volatile is read: 2
XXX    times read thru a pointer: 0
XXX times a volatile is write: 0
XXX    times written thru a pointer: 0
XXX times a volatile is available for access: 4
XXX percentage of non-volatile access: 81.8

XXX forward jumps: 0
XXX backward jumps: 0

XXX stmts: 9

XXX percentage a fresh-made variable is used: 55.6
XXX percentage an existing variable is used: 44.4
********************* end of statistics **********************/

