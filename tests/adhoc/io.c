#include <stdio.h>
#include <stdlib.h>

int main(void) {
	FILE * fp = fopen("adhoc/inp.txt", "r");
	int myChar;
	while((myChar = fgetc (fp)) != EOF) {
		putchar(myChar);
	}
	
	fclose(fp);
	printf("%d\n", 32);
	return 0;
}

