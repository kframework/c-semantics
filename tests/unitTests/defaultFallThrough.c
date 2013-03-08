#include <stdio.h>
int main(void){
	switch(5) {
		case 5: printf("5\n");
		default:
			printf("default\n");
		case 6: printf("6\n");
			break;
	}
}

