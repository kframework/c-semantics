int f(int x){
	return x;
}

int main(void){
	int (*x)(double) = &f;
	return x(5);
}
