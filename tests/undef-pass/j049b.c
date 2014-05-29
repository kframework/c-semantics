int main(void){
	int a[4][3] = {}; // theoretically 4 * 3 memory slots
	int z = a[0][0]; // but not allowed to go out of bounds in any dimension
	return 0;
}
