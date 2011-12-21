double x, y;
double* p0 = &x;
double *p = (double*)&x;
int main(void){
	return *p;
}
