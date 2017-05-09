union U {
	char a;
	int b;
} u;

int main(void){
	u.b = 0;
	u.a = 0;
        // u.b is now unspecified
	if (0) u.a - 1;
}
