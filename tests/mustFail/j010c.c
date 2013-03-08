int main(void){
	int i = 0;
	int* p;
	while (i < 10){
		int x = 2;
		i++;
		p = &x;
	}
	*p;
	return 0;
}
