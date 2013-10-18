void exit(int status);
void abort(void);
void f(got){if(got!=0xffff)abort();}
int main(){signed char c=-1;unsigned u=(unsigned short)c;f(u);exit(0);}
