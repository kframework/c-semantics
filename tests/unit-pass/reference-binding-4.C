int alpha = -1;
int & foo() { return alpha; }
int & beta = foo();
int main() {
	beta++;
	return alpha;
}
