int main(void){
	int *p;
	if (1) {
		int x = 0;
		p = &x;
	}
	return *p;
}
