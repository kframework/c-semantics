void exit(int status);
void abort(void);
static inline fu (unsigned short data)
{
  return data;
}
void ru(i)
{
   if(fu(i++)!=5)abort();
   if(fu(++i)!=7)abort();
}
static inline fs (signed short data)
{
  return data;
}
void rs(i)
{
   if(fs(i++)!=5)abort();
   if(fs(++i)!=7)abort();
}


int main()
{
  ru(5);
  rs(5);
  exit(0);
}
