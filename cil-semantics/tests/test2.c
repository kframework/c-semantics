int main()
{
  unsigned int i0 ;
  unsigned int i1 ;
  unsigned int i2 ;
  int i3 ;
  int i4 ;
  int i5 ;
  int i6 ;

  {
  i0 = 256U;
  i1 = i0 + 1024U;
  i2 = i1 + 4294967040U;
  i3 = 256;
  i4 = i3 + 1024;
  i5 = i4 + -2048;
  i6 = i5 + -2147483648;

  return i6;
}
}

