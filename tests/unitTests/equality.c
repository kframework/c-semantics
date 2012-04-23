int y;
int main(void){
	int x;
	
	if ((void*)&main == (void*)&x){ return 1; }
	if (100 == 50){ return 2; }
	if (-100 == 50){ return 3; }
	if (-100 == 3.5){ return 4; }
	if ((void*)0 == (void*)&x){ return 5; }
	if ((void*)0 != (void*)0){ return 6; }
	if (-1 != -1){ return 7; }
	if (&x != &x){ return 8; }
	if (&main != &main){ return 9; }
	if (&y != &y){ return 10; }
	if ((void*)&main == (void*)&y){ return 11; }
	if (!((void*)0 == (void*)0)){ return 106; }
	if (!(-1 == -1)){ return 107; }
	if (!(&x == &x)){ return 108; }
	if (!(&main == &main)){ return 109; }
	if (!(&y == &y)){ return 110; }
	
	return 0;
}
