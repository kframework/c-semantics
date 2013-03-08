/*
 * This is a RANDOMLY GENERATED PROGRAM.
 *
 * Generator: csmith 2.0.0
 * svn version: exported
 * Options:   --check-global -s 572
 * Seed:      572
 */

#include "random_runtime.h"


long __undefined;

/* --- Struct/Union Declarations --- */
/* --- GLOBAL VARIABLES --- */
 volatile uint16_t g_2 = 0x49FEL;/* VOLATILE GLOBAL g_2 */
 volatile uint8_t g_3 = -7L;/* VOLATILE GLOBAL g_3 */
int32_t g_12 = 0x0A3267E6L;
int32_t * const  volatile g_11[1] = {&g_12};
int32_t *g_24 = &g_12;
int32_t ** const g_23[3] = {&g_24, &g_24, &g_24};


/* --- FORWARD DECLARATIONS --- */
int16_t  func_1(void);
int32_t * func_4(int32_t * p_5);
int32_t  func_17(int32_t ** const  p_18, uint64_t  p_19, int16_t  p_20);


/* --- FUNCTIONS --- */
/* ------------------------------------------ */
/* 
 * reads : g_2 g_3 g_11 g_23 g_12
 * writes: g_3 g_12 g_2
 */
int16_t  func_1(void)
{ /* block id: 0 */
    int32_t *l_16 = 0;
    int32_t **l_15 = &l_16;
    int32_t l_28 = 0x69FF4CAAL;
    g_3 = g_2;
    (*l_15) = func_4(&g_12);
    if ((0 == (*l_15)))
    { /* block id: 15 */
        int16_t l_25 = 1L;
        (*l_16) = func_17(g_23[2], l_25, (safe_sub_func_int8_t_s_s((*l_16), l_25)));
        (**l_15) ^= l_28;
    }
    else
    { /* block id: 21 */
        return g_3;
    }
    return g_2;
}


/* ------------------------------------------ */
/* 
 * reads : g_3 g_11
 * writes: g_3 g_2 g_12
 */
int32_t * func_4(int32_t * p_5)
{ /* block id: 2 */
    int16_t l_13 = -1L;
    int32_t l_14 = 0x8018D9DCL;
    (*p_5) = (g_3 < (safe_lshift_func_uint8_t_u_s(0x09978F3CL, 0xEEA2A3B3L)));
    (*p_5) = g_3;
    for (g_3 = 0; (g_3 >= 9); g_3 = safe_add_func_uint64_t_u_u(g_3, 1))
    { /* block id: 7 */
        int32_t l_10[7][10];
        int i, j;
        for (i = 0; i < 7; i++)
        {
            for (j = 0; j < 10; j++)
                l_10[i][j] = 0L;
        }
        for (g_2 = 0; g_2 < 7; g_2 += 3)
        {
            for (g_3 = 6; g_3 >= 0; g_3 += -10)
            { /* block id: 8 */
                (*p_5) = (g_11[0] != p_5);
                l_14 |= l_13;
            }
        }
    }
    return &g_12;
}


/* ------------------------------------------ */
/* 
 * reads :
 * writes: g_12
 */
int32_t  func_17(int32_t ** const  p_18, uint64_t  p_19, int16_t  p_20)
{ /* block id: 16 */
     const int8_t l_21 = 0xD2L;
    int32_t *l_22 = &g_12;
    (*l_22) = l_21;
    return p_19;
}




/* ---------------------------------------- */
int main (int argc, char* argv[])
{
    int i;
    func_1();
    printf("checksum g_2 = %d\n", g_2);
    printf("checksum g_3 = %d\n", g_3);
    printf("checksum g_12 = %d\n", g_12);
}

/************************ statistics *************************
XXX max struct depth: 0
breakdown:
   depth: 0, occurrence: 14

XXX max expression depth: 1
breakdown:
   depth: 0, occurrence: 13
   depth: 1, occurrence: 1

XXX total number of pointers: 8

XXX times a variable address is taken: 5
XXX times a pointer is dereferenced on RHS: 2
breakdown:
   depth: 1, occurrence: 2
XXX times a pointer is dereferenced on LHS: 7
breakdown:
   depth: 1, occurrence: 6
   depth: 2, occurrence: 1
XXX times a pointer is compared with null: 1
XXX times a pointer is compared with address of another variable: 0
XXX times a pointer is compared with another pointer: 1
XXX times a pointer is qualified to be dereferenced: 17

XXX max dereference level: 2
breakdown:
   level: 0, occurrence: 0
   level: 1, occurrence: 18
   level: 2, occurrence: 4
XXX number of pointers point to pointers: 3
XXX number of pointers point to scalars: 5
XXX number of pointers point to structs: 0
XXX percent of pointers has null in alias set: 12.5
XXX average alias set size: 1.12

XXX times a non-volatile is read: 13
XXX times a non-volatile is write: 16
XXX times a volatile is read: 7
XXX    times read thru a pointer: 0
XXX times a volatile is write: 2
XXX    times written thru a pointer: 0
XXX times a volatile is available for access: 9
XXX percentage of non-volatile access: 76.3

XXX forward jumps: 0
XXX backward jumps: 0

XXX stmts: 25

XXX percentage a fresh-made variable is used: 40.9
XXX percentage an existing variable is used: 59.1
********************* end of statistics **********************/

