int* f(int z){
	{ 
		return &z;
	}
}
int main(void){
	f(5);
	int y = 0;
	return 0;
}
