int y;
int* f(void) {
	int x;
	return &y;
}
int main(void) {
	int* p = f();
}
