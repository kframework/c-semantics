int x, y;
int* a1 = &x;
int** a = &a1;
int *p = &*((int*)0);
int main(void){
	int *p2 = 0;
	
	return p != p2;
}
