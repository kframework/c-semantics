void exit(int status);
void abort(void);
void f (x, y)
{
  if (x % y != 0)
    abort ();
}

int main ()
{
  f (-5, 5);
  exit (0);
}
