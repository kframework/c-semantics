void exit(int status);
void abort(void);
int
f (b)
{
  return (b >> 1) > 0;
}

int main ()
{
  if (!f (9))
    abort ();
  if (f (-9))
    abort ();
  exit (0);
}
