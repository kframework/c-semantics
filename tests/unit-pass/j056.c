struct {
      int f;
} s;

static int f(void) {
	return 0;
}

int x = 5 - 5;
int a[5];
int* p1 = (int*)0;
int* p2 = &a[2];
int* p3 = &s.f;

int main(void){
	return *p2;
}

