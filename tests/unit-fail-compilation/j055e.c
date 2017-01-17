#include<limits.h>
int x;
enum e {a = 5 + ((long)&x & LONG_MAX)};
int main(void){

}
