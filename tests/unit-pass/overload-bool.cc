int f(int  x){return 1;}
int f(char x){return 1;}
int f(bool x){return 0;}

int
main ()
{
  bool b = true; 
  return f(b);
}

