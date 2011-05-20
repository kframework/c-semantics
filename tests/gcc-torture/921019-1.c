void exit(int status);
void abort(void);
void *foo[]={(void *)&("X"[0])};

main ()
{
  if (((char*)foo[0])[0] != 'X')
    abort ();
  exit (0);
}
