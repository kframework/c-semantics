#include <stdio.h>
int main(void){
	((!(5 == 5)) ? (printf("a"),(void)0) : (printf("b"),(void)0));
	((!(6 == 7)) ? (printf("c"),(void)0) : (printf("d"),(void)0));
}
