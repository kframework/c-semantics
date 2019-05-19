int main() {
	int a = 3;
	int b{static_cast<int &&>(a)};
	return b - 3;
}
