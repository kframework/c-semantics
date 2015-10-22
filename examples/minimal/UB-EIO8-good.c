int foo (int *p1, int *p2)
{
 return (*p1)++ + (*p2)++;
}

int main (void)
{
 int a = 0;
 int b = 0;
 foo (&a, &b);
 return 0;
}
