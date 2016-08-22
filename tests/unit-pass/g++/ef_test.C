/* { dg-do run }  */
/* { dg-options "-fcilkplus" } */


int func (int x)
{
  return x+5;
}


int func2 (int x, int y)
{
  return x+y;
}

int func4 (int x, int y);


template <class T, class R>
T func3 (T x, R y)
{
  return x+(T)y;
}



int main (void)
{
  if ((func3 (5, 4) + func2 (5, 4) + func (5) + (int) func3<long, int> (5, 4)) != 
      (5 + 4) + (5 + 4) + (5 + 5) + (int) ((long)5 +(int)4))
    __builtin_abort ();
  return 0;
}
