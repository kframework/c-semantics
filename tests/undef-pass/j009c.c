int* f(){
	{ 
		int x = 5;
		return &x;
	}
}
int main(void){
	f();
	int y = 0;
	return 0;
}
