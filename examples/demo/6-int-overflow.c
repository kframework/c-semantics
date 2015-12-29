// KCC is also able to detect integer overflow operations and assignments of
// values to data types triggering loss of precision that occur while the
// program is executing.  According to the C standard, integer overflow
// (an arithmetic operation whose result does not fit in the specified type)
// is considered undefined behavior.  However, in the following program, a
// short int is automatically promoted to the int type at every
// multiplication, and therefore what occurs is not overflow but merely a
// conversion to a type that cannot store the specified value.  The C standard
// considers this case to be implementation defined behavior, which is
// unspecified behavior where each implementation documents how the choice
// is made.  KCC can be instantiated with different profiles corresponding
// to different implementation choices (type kcc -v to see the existing
// profiles; contact https://runtimeverification.com/support if you are
// interested in a specific profile that is not available).  For example,
// while with conventional compilers the program below reports no errors
// when executed, with the default kcc profile (x86_64 on linux) it reports
// an error, but no error is reported if you declare variable a as an int
// instead of a short int, or if you iterate 14 times instead of 15.
// If you declared a as an int and iterated 31 times, you would see undefined
// behavior corresponding to a "true" overflow.  However, in actual fact,
// because the below program as written is implementation-defined, on some
// systems it may in fact raise an arithmetic signal terminating the
// application at the point of the lossy conversion.

int main() {
  short int a = 1;
  int i;
  for (i = 0; i < 15; i++) {
    a *= 2;
  }
  return a;
}
