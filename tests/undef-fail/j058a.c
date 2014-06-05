int x, y;
int* a[2] = {&x, &y};

int *p = a[0];
int main(void){
	return *p;
}
