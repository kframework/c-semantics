struct S {};
int counter = 0;
void foo(S const &&){counter++;}
void foo(S const &){counter--;}

int main() {
	S a;
	foo(a);
	return 1 + counter;
}
