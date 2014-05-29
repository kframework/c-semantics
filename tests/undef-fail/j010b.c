int* f(void) {
	int x;
	return &x;
}
int main(void) {
	int* p = f();
}
