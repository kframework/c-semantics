/*
 * This is a RANDOMLY GENERATED PROGRAM.
 *
 * Generator: csmith 2.0.0
 * svn version: exported
 * Options:   --check-global -s 1722
 * Seed:      1722
 */

#include "random_runtime.h"


long __undefined;

/* --- Struct/Union Declarations --- */
/* --- GLOBAL VARIABLES --- */
int32_t g_3 = 9L;
int32_t *g_6 = &g_3;
int32_t ** volatile g_5 = &g_6;/* VOLATILE GLOBAL g_5 */
uint16_t g_17 = 0xD1AFL;


/* --- FORWARD DECLARATIONS --- */
uint16_t  func_1(void);
int32_t  func_12(int32_t  p_13, uint16_t  p_14, int64_t  p_15, int32_t ** p_16);


/* --- FUNCTIONS --- */
/* ------------------------------------------ */
/* 
 * reads : g_5 g_3 g_6 g_17
 * writes: g_3 g_6 g_17
 */
uint16_t  func_1(void)
{ /* block id: 0 */
    int64_t l_2[7];
    uint8_t l_19 = -7L;
    int32_t **l_22 = &g_6;
    int32_t l_26 = 0L;
    int i;
    for (i = 0; i < 7; i++)
        l_2[i] = 1L;
    for (g_3 = 6; g_3 >= 0; g_3 += -1)
    { /* block id: 1 */
        int32_t *l_4[3];
        int16_t l_23 = -9L;
        int i;
        for (i = 0; i < 3; i++)
            l_4[i] = &g_3;
        (*g_5) = l_4[2];
        if (g_3)
            goto lbl_7;
lbl_7:
        if (l_2[(uint32_t)(g_3) % 7])
            continue;
        l_23 |= (safe_div_func_int8_t_s_s(l_2[2], (((l_2[0] != 0x9D585ED0L) && (safe_rshift_func_uint16_t_u_s((**g_5), l_2[(uint32_t)(g_3) % 7]))) == func_12(l_2[(uint32_t)(g_3) % 7], (((~l_2[4]) > (l_19 > (*g_6))) > (*g_6)), func_12((*g_6), g_3, func_12((*g_6), (safe_mul_func_int8_t_s_s((*g_6), (*g_6))), ((*g_6) && (*g_6)), &g_6), l_22), &g_6))));
        for (l_23 = 0; (l_23 <= 0); l_23 = safe_add_func_int32_t_s_s(l_23, 1))
        { /* block id: 11 */
            int64_t l_29[5][4];
            int i, j;
            for (i = 0; i < 5; i++)
            {
                for (j = 0; j < 4; j++)
                    l_29[i][j] = 0xCA4B38B4B72B416CLL;
            }
            l_26 &= ((*l_22) != (*l_22));
            for (g_17 = 0; (g_17 <= -6); g_17 = safe_add_func_int32_t_s_s(g_17, 1))
            { /* block id: 15 */
                return l_29[3][2];
            }
        }
    }
    return g_17;
}


/* ------------------------------------------ */
/* 
 * reads : g_17 g_6 g_3
 * writes:
 */
int32_t  func_12(int32_t  p_13, uint16_t  p_14, int64_t  p_15, int32_t ** p_16)
{ /* block id: 5 */
    int32_t l_18 = -9L;
    l_18 = g_17;
    return (*g_6);
}




/* ---------------------------------------- */
int main (int argc, char* argv[])
{
    func_1();
    printf("checksum g_3 = %d\n", g_3);
    printf("checksum g_17 = %d\n", g_17);
}

/************************ statistics *************************
XXX max struct depth: 0
breakdown:
   depth: 0, occurrence: 11

XXX max expression depth: 0
breakdown:
   depth: 0, occurrence: 7

XXX total number of pointers: 5

XXX times a variable address is taken: 3
XXX times a pointer is dereferenced on RHS: 12
breakdown:
   depth: 1, occurrence: 11
   depth: 2, occurrence: 1
XXX times a pointer is dereferenced on LHS: 1
breakdown:
   depth: 1, occurrence: 1
XXX times a pointer is compared with null: 0
XXX times a pointer is compared with address of another variable: 0
XXX times a pointer is compared with another pointer: 1
XXX times a pointer is qualified to be dereferenced: 37

XXX max dereference level: 2
breakdown:
   level: 0, occurrence: 0
   level: 1, occurrence: 18
   level: 2, occurrence: 5
XXX number of pointers point to pointers: 3
XXX number of pointers point to scalars: 2
XXX number of pointers point to structs: 0
XXX percent of pointers has null in alias set: 0
XXX average alias set size: 1

XXX times a non-volatile is read: 39
XXX times a non-volatile is write: 6
XXX times a volatile is read: 1
XXX    times read thru a pointer: 0
XXX times a volatile is write: 1
XXX    times written thru a pointer: 0
XXX times a volatile is available for access: 4
XXX percentage of non-volatile access: 95.7

XXX forward jumps: 1
XXX backward jumps: 0

XXX stmts: 21

XXX percentage a fresh-made variable is used: 26.7
XXX percentage an existing variable is used: 73.3
********************* end of statistics **********************/

