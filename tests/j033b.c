int main(void){
	char (*s)[6];
	s = &"hello";
	(*s)[0];
}
