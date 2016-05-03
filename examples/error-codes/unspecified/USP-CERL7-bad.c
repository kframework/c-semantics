union U {
	char a;
	int b;
} u;

int main(void){
	u.b = 0;
	u.a = 0;
	if (u.b) u.a - 1;
}
