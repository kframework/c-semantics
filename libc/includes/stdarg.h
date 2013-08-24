#ifndef _KCC_STDARG_H
#define _KCC_STDARG_H
#include <kcc_settings.h>
#include <stddef.h>

#include <stdlib.h>
typedef void* va_list;

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
// type va_arg(va_list ap, type);
#define __va_argsiz(t)	((sizeof(t)))
va_list __va_inc(va_list* ap, size_t size); // increments the ap, and returns the current vararg
#define va_arg(ap, t) \
	(*((t*)(__va_inc((&(ap)), (__va_argsiz(t))))))

// void va_start(va_list ap, parmN);
void __va_start(va_list* ap, void* pN);
#define va_start(ap, pN) \
	(__va_start((&(ap)), ((void*)(&(pN)))))

// void va_end(va_list ap);
void __va_end(va_list* ap);
#define va_end(ap) \
	(__va_end(&(ap)))

// void va_copy(va_list dest, va_list src);
void __va_copy(va_list* dst, va_list src);
#define va_copy(dst, src) \
	(__va_copy((&(dst)), (src)))

#endif
