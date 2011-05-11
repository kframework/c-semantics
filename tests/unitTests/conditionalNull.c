int main(void){
	int i = 5;
	int *p;
	p = ((2 == 3) ? 0 : &i);
	return *p;
}
