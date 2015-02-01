int main(void) {
	volatile int x = 5;
	*(int*)&x;
	return 0;
}
