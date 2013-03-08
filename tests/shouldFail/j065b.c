int f(int* x) {
	return *x;
}
int main(void) {
	volatile int x = 5;
	f(&x);
	return 0;
}
