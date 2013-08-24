#ifndef _KCC_LOCALE_H
#define _KCC_LOCALE_H
#include <kcc_settings.h>
#include <stddef.h>

#ifndef _KCC_EXPERIMENTAL_LOCALE
#error locale.h not supported
#endif

struct lconv {
	char *decimal_point;
	char *thousands_sep;
	char *grouping;
	char *mon_decimal_point;
	char *mon_thousands_sep;
	char *mon_grouping;
	char *positive_sign;
	char *negative_sign;
	char *currency_symbol;
	char frac_digits;
	char p_cs_precedes;
	char n_cs_precedes;
	char p_sep_by_space;
	char n_sep_by_space;
	char p_sign_posn;
	char n_sign_posn;
	char *int_curr_symbol;
	char int_frac_digits;
	char int_p_cs_precedes;
	char int_n_cs_precedes;
	char int_p_sep_by_space;
	char int_n_sep_by_space;
	char int_p_sign_posn;
	char int_n_sign_posn;
};

/* when in the "C" locale, the struct will have the following values:
char *decimal_point;
// "."
char *thousands_sep;
// ""
char *grouping;
// ""
char *mon_decimal_point;
// ""
char *mon_thousands_sep;
// ""
char *mon_grouping;
// ""
char *positive_sign;
// ""
char *negative_sign;
// ""
char *currency_symbol;
// ""
char frac_digits;
// CHAR_MAX
char p_cs_precedes;
// CHAR_MAX
char n_cs_precedes;
// CHAR_MAX
char p_sep_by_space;
// CHAR_MAX
char n_sep_by_space;
// CHAR_MAX
char p_sign_posn;
// CHAR_MAX
char n_sign_posn;
// CHAR_MAX
char *int_curr_symbol;
// ""
char int_frac_digits;
// CHAR_MAX
char int_p_cs_precedes;
// CHAR_MAX
char int_n_cs_precedes;
// CHAR_MAX
char int_p_sep_by_space;
// CHAR_MAX
char int_n_sep_by_space;
// CHAR_MAX
char int_p_sign_posn;
// CHAR_MAX
char int_n_sign_posn;
// CHAR_MAX
*/

#define LC_ALL 1
#define LC_COLLATE 2
#define LC_CTYPE 3
#define LC_MONETARY 4
#define LC_NUMERIC 5
#define LC_TIME 6

char *setlocale(int category, const char *locale);
struct lconv *localeconv(void);

#endif
