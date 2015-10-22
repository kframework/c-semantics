struct node {
	struct node* p;
	int v;
} s;

struct node f(void){
	return s;
}

int main(void){
	s.p = &s;
	s.v = 5;
	
	f().p;
	return 0;
}
