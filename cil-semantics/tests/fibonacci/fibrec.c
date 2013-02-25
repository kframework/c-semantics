int fibrec(int n)
{
   if ( n == 0 )
      return 0;
   else if ( n == 1 )
      return 1;
   else
      return ( fibrec(n-1) + fibrec(n-2) );
}

int main()
{
  return fibrec(10);
}

