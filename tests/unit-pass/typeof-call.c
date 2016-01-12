long foo() {
  return  0;
}

long bar(int x) {
  return x;
}

long (*verify)() = foo;
long (*verify2)(int maxbits) = bar;

int main() {
   int x = 0 ? foo() : bar(5);
	return (0 ?
		verify2(0) :
		verify());
}
