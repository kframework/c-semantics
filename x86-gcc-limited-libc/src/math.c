#include <math.h>

int abs(int num) {
	if (num >= 0) {
		return num;
	} else {
		return -num;
	}
}
double fabs(double num) {
	if (num >= 0.0) {
		return num;
	} else {
		return -num;
	}
}
double pow(double x, double y) {
	if (x == 0 && y == 0) {
		return 1; // this is what gcc seems to do
	}
	if (x == 0 && y != 0) {
		return 0;
	}
	if (y == 0 && x != 0) {
		return 1;
	}
	if (x < 0) {
		if (y/1.00 == (int)y) {
			if ((int)y % 2) {
				return -exp(y*log(-x));
			} else {
				return exp(y*log(-x));
			}
		}
	}
	return exp(y*log(x));
	// 	+ 1e-6;
}
