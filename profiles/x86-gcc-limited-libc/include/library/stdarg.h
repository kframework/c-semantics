#ifndef _STDARG_H
#define _STDARG_H
#include <stddef.h>

#define __builtin_va_list __kcc_va_list
#define __gnuc_va_list __kcc_va_list
typedef __kcc_va_list va_list;

#ifdef __cplusplus
extern "C" {
#endif

/* The va_arg macro expands to an expression that has the specified type and
 * the value of the next argument in the call. The parameter ap shall have been
 * initialized by the va_start or va_copy macro (without an intervening
 * invocation of the va_end macro for the same ap). Each invocation of the
 * va_arg macro modifies ap so that the values of successive arguments are
 * returned in turn. The parameter type shall be a type name specified such
 * that the type of a pointer to an object that has the specified type can be
 * obtained simply by postfixing a * to type. If there is no actual next
 * argument, or if type is not compatible with the type of the actual next
 * argument (as promoted according to the default argument promotions), the
 * behavior is undefined, except for the following cases:
 *
 * one type is a signed integer type, the other type is the corresponding
 * unsigned integer type, and the value is representable in both types;
 *
 * one type is pointer to void and the other is a pointer to a character type.
 */
/* type va_arg(va_list ap, type); */
#define va_arg(ap, t) (*((t*)(__kcc_va_inc((ap)))))
void *__kcc_va_inc(va_list ap); // increments the ap, and returns the current vararg

/* void va_start(va_list ap, parmN); */
#define va_start(ap, pN) (__kcc_va_start((&(ap)), ((void*)(&(pN)))))
void __kcc_va_start(va_list *ap, void *pN);

#define va_end __kcc_va_end
void __kcc_va_end(va_list ap);

/* void va_copy(va_list dst, va_list src); */
#define va_copy(dst, src) (__kcc_va_copy((&(dst)), (src)))
void __kcc_va_copy(va_list *dst, va_list src);

#ifdef __cplusplus
}
#endif

#endif
