// kcc-assert-error(00035)
int main(void) {
	int a[2] = {1, 2};
	a[0] = 0;
	return a[0];
}
