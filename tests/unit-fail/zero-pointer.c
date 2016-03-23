#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct test_struct {
  void *               r;
  int                  y;
  double               x;
  long                 z;
  char                 str[348];
  struct test_struct * next;
  struct test_struct * prev;

} test_struct;

int main()
{
  void *        voidp   = NULL;
  char          zeroes[sizeof(test_struct)];

  memset(zeroes, 0, sizeof(zeroes));

  const void *s1 = &voidp;
  const void *s2 = zeroes;
  size_t n = sizeof(voidp);
  const unsigned char *us1 = (const unsigned char *) s1;
  const unsigned char *us2 = (const unsigned char *) s2;
  while (n-- != 0) {
        if (*us1 != *us2) {
              return (*us1 < *us2) ? -1 : +1;
        }
        us1++;
        us2++;
  }
     
  return 100;
}

