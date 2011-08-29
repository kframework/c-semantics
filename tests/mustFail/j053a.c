// kcc-assert-error(00033)
int main(void) {
	int a;
	int b;
	if (&a >= &b) {
		return 0;
	}
}
