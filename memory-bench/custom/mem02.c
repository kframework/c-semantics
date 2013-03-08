int main(void){
	int *p = 0;
	trick:
	if (p) { return *p; }
	
	if (1) {
		int x = 0;
		p = &x;
		goto trick;
	}
}
