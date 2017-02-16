/* Copyright (C) 1991-2016 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <http://www.gnu.org/licenses/>.  */

#include <stdio.h>

#define N 64

int
main (void)
{
  FILE *fp;
  int i, j;

  char* name = tmpnam(NULL);

  puts ("\nFile seek test");
  fp = fopen (name, "w");
  if (fp == NULL)
    {
      perror (name);
      return 1;
    }

  for (i = 0; i != N; i++)
    putc (i, fp);
  if (freopen (name, "r", fp) != fp)
    {
      perror ("Cannot open file for reading");
      return 1;
    }

  for (i = 1; i != N; i++)
    {
      printf ("%3d\n", i);
      // fseek (fp, (long) -i, SEEK_END);
      // if ((j = getc (fp)) != 256 - i)
	// {
	//   printf ("SEEK_END failed %d\n", j);
	//   break;
	// }
      if (fseek (fp, (long) i, SEEK_SET))
	{
	  puts ("Cannot SEEK_SET");
	  break;
	}
      if ((j = getc (fp)) != i)
	{
	  printf ("SEEK_SET failed %d\n", j);
	  break;
	}
      if (fseek (fp, (long) i, SEEK_SET))
	{
	  puts ("Cannot SEEK_SET");
	  break;
	}
      if (fseek (fp, (long) (i >= (N/2) ? -(N/2) : (N/2)), SEEK_CUR))
	{
	  puts ("Cannot SEEK_CUR");
	  break;
	}
      if ((j = getc (fp)) != (i >= (N/2) ? i - (N/2) : i + (N/2)))
	{
	  printf ("SEEK_CUR failed %d\n", j);
	  break;
	}
    }
  fclose (fp);
  remove (name);

  puts ((i == N) ? "Test succeeded." : "Test FAILED!");
  return (i == N) ? 0 : 1;
}

