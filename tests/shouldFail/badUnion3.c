union U {
	int a[2];
	int b;
} u;

int main(void){
	u.b = 0;
	u.a[0] = 0;
	return u.b;	
}
