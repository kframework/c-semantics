int main(void) {
	volatile int x = 5;
	*(volatile int*)&x;
	return 0;
}
