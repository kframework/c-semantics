int f(int x){
	return x;
}

int main(void){
	int (*x)(double) = (int (*)(double))&f;
	return x(5);
}
