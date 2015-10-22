struct _s {
	int x;
	int a[];
} s;

int main(void){
	&(s.a[1]);
}
