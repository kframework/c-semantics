int f(int x){
	return x;
}

int main(void){
	int (*x)(int) = &f;
	return x(0);
}
