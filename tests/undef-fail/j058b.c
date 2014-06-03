int x, y;
struct {
	int* p1;
	int* p2;
} a = {&x, &y};

int *p = a.p1;
int main(void){
	return *p;
}
