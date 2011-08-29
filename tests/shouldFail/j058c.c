int x, y;
struct _a {
	int* p1;
	int* p2;
} a = {&x, &y};
struct _a *ap = &a;
int *p = ap->p1;
int main(void){
	return *p;
}
