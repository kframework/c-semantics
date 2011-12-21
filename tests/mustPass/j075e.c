int f();

int main(void){
	int x = 5;
	int* const p = &x;
	return f(p);
}

int f(int * const p){
	return *p != 5;
}
