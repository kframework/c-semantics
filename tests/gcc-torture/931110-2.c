void exit(int status);
void abort(void);
main ()
{
  static int a[] = {3, 4};
  register int *b;
  int c;

  b = a;
  c = *b++ % 8;
  if (c != 3)
    abort ();
  exit (0);
}
