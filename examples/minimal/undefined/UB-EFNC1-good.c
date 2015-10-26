int f(int x){
	return x;
}

int main(void){
	int (*x)(int) = (int (*)(int))&f;
	return x(0);
}
