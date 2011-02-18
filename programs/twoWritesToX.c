int main(void) {
	int x = 0;
	return (x = 1) + (x = 2); // two unsequenced writes to x.  Undefined!
}

/* 
Undefined according to C standard

GCC4, MSVC: returns 4
GCC3, ICC, Clang: returns 3

Both Frama-C and Havoc "prove" it returns 4
*/
