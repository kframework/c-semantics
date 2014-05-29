int* f(){
	int z = 6;
	{ 
		int x = 5;
		return &z;
	}
}
int main(void){
	int* p = f();
	int y = *p;
	return 0;
}
