union { int i; int d; } id;
int main(void) {
	id.d = id.i;
	return id.d;
}

// strangely, I think the below is defined
// union { double i; double d; } id;
// int main(void) {
	// id.d = (int)id.i;
// }
