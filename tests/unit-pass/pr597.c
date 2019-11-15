#include <stdlib.h>
void foo(char *restrict s, char **psave) {
	*psave = s;
}

// at least one parameter must be `restrict` to trigger the error
void bar(char **psave, const char *restrict unused) {
	char * send = *psave;
	*send = '\0';
}

int main() {
	char tmp[] = "1,0,2";
	char *save = "";
	foo(tmp, &save);
	bar(&save, NULL);
	return 0;
}
