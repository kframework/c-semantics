#include <stddef.h>
int main(void){
	int retval = 0;
	
	wchar_t c;
	c = L'x';
	retval = c;
	
	char* z;
	z = &("bar");
	retval += z[0];
	
	wchar_t* s;
	s = &(L"foo");
	retval += s[0];

	return retval;
}
