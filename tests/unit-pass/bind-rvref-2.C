void foo(int && y) {
	y--;
}

int main() {
	int a = 2;
	int && x = static_cast<int &&>(a);
	x--;
	foo(static_cast<int &&>(a));
	return a;
}
