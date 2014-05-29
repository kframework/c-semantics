int x, y;
int* a1 = &x;
int** a = &a1;
int *p = *a;
int main(void){
	return *p;
}
