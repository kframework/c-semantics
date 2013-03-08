int r;
int f(){
	return r++;
}
int main(void){
	return f() + (r+=1);
}
