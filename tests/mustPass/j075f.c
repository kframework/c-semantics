int f();

int main(void){
	const int x = 5;
	const int* p = &x;
	return f(p);
}

int f(const int * p){
	return *p != 5;
}
