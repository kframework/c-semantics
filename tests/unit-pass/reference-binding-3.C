struct S {
	int a;
	int &b;
	S() : b(a) {}
};
int main() {
	S s;
	s.b = 1;
	return s.a - 1;
}

