union U {
	char a;
	int b;
} u;

int main(void){
	u.b = 0;
	u.a = 0;
	switch(u.b) {
        case 1:
            break;
        }
}
