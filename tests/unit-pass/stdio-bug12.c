#include <stdio.h>
#include <string.h>

#define N 256

char x[N], z[N], b[21], m[N * 4];

int
main (void)
{
  FILE *f = tmpfile ();
  int i, failed = 0;

  memset (x, 'x', N);
  memset (z, 'z', N);
  b[20] = 0;

  for (i = 0; i <= 5; i++)
    {
      fwrite (x, N, 1, f);
      fwrite (z, N, 1, f);
    }
  rewind (f);

  fread (m, N * 4 - 10, 1, f);
  fread (b, 20, 1, f);
  printf ("got %s (should be %s)\n", b, "zzzzzzzzzzxxxxxxxxxx");
  if (strcmp (b, "zzzzzzzzzzxxxxxxxxxx"))
    failed = 1;

  fseek (f, -40, SEEK_CUR);
  fread (b, 20, 1, f);
  printf ("got %s (should be %s)\n", b, "zzzzzzzzzzzzzzzzzzzz");
  if (strcmp (b, "zzzzzzzzzzzzzzzzzzzz"))
    failed = 1;

  fread (b, 20, 1, f);
  printf ("got %s (should be %s)\n", b, "zzzzzzzzzzxxxxxxxxxx");
  if (strcmp (b, "zzzzzzzzzzxxxxxxxxxx"))
    failed = 1;

  fread (b, 20, 1, f);
  printf ("got %s (should be %s)\n", b, "xxxxxxxxxxxxxxxxxxxx");
  if (strcmp (b, "xxxxxxxxxxxxxxxxxxxx"))
    failed = 1;

  return failed;
}
