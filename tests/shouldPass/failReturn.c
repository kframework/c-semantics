// This program should run.  "The } that terminates a function is reached, and the value of the function call is not used by the caller (6.9.1)."

int f(void){
}

int main(void){
	f();
	return 0;
}
