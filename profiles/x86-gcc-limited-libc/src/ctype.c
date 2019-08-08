#include <ctype.h>

int isprint(int c){
	if (c <= 0x1f || c == 0x7f) {
		return 0;
	} else {
		return 1;
	}
	return 1;
}
