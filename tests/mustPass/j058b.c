int x, y;
struct {
	int p1;
	int p2;
} a = {0, 1};

int *p = &(a.p1);
int main(void){
	return *p;
}
