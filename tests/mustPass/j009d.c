// this program shouldn't run

int* f(){
	int z = 6;
	{ 
		int x = 5;
		return &z;
	}
}
int main(void){
	f();
	int y = 0;
	return 0;
}
