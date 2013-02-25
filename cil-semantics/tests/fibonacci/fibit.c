int fibit(int n)
{
   int first = 0, second = 1, next, c;
 
   if (n<=1) {
     next=n;
   } else {
     for ( c = 2 ; c <= n ; c++ ) {
       next = first + second;
       first = second;
       second = next;
     }
   }
   
   return next;
}

int main()
{
  return fibit(10);
}

