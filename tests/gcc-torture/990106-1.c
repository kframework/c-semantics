void exit(int status);
void abort(void);
foo(bufp)
char *bufp;
{
    int x = 80;
    return (*bufp++ = x ? 'a' : 'b');
}

main()
{
  char x;

  if (foo (&x) != 'a')
    abort ();

  exit (0);
}
