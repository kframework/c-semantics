int r;

int f(int x) {
	return (r = x);
}

int main(void) {
	return f(1) + f(2),  r;
}
