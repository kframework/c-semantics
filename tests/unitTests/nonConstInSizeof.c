int x;
enum e { a = sizeof((int)&x) };
int main(void){
	enum e x = a;
	return x;
}
