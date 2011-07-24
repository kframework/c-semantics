union T {
	char a;
};

union U {
	union T t;
	int b;
} u;

int main(void){
	u.b = 0;
	u.t.a = 0;
	return u.b;	
}
