int main(void){
	const int x = 0;
	int* p = &x;
	*p = 5;
	return x;
}
