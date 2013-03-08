int x, y;
struct _a {
	int p1;
	int p2;
} a = {0, 1};
struct _a *ap = &a;
int *p = &((&a)->p1);
int main(void){
	return *p;
}
