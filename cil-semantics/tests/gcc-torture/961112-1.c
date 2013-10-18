void exit(int status);
void abort(void);
int f (x)
{
  if (x != 0 || x == 0)
    return 0;
  return 1;
}

int main ()
{
  if (f (3))
    abort ();
  exit (0);
}
