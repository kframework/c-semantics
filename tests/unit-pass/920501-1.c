void exit(int status);
void abort(void);
int s[2];
int x(int q){if(!s[0]){s[1+s[1]]=s[1];return 1;}}
int main(){s[0]=s[1]=0;if(x(0)!=1)abort();exit(0);}
