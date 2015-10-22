#include <limits.h>
int main(void){
	return (int)1 >> sizeof(int) * CHAR_BIT;
}
