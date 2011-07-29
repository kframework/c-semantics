void exit(int status);
void abort(void);
int f(x){int i;for(i=0;i<8&&(x&1)==0;x>>=1,i++);return i;}
int main(){if(f(4)!=2)abort();exit(0);}
