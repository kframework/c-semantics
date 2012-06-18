#include <threads.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct {
	int *b;
	int *e;
} qsort_arg;

void quickSort(void* arg) {
	int* b = ((qsort_arg*)arg)->b;
	int* e = ((qsort_arg*)arg)->e;
	
	int t;
	if (! (e <= b + 1)) {
		int p = *b; int *l = b+1; int *r = e;
		while (l + 1 <= r) {
			if (*l <= p) {
				l = l + 1;
			} else {
				r = r - 1;
				//printf("swapping %d with %d\n", *l, *r);
				t = *l; *l = *r; *r = t;
			}
		}
		l = l - 1;
		//printf("swapping %d with %d\n", *l, *b);
		t = *l; *l = *b; *b = t;
		
		qsort_arg* arg1 = malloc(sizeof(qsort_arg));
		arg1->b = b; arg1->e = l;
		qsort_arg* arg2 = malloc(sizeof(qsort_arg));
		arg2->b = r; arg2->e = e;
		//printf("recursing...\n");
		thrd_t t1, t2;
		thrd_create(&t1, quickSort, arg1);
		thrd_create(&t2, quickSort, arg2);
		//thrd_join(t1, NULL);
		//thrd_join(t2, NULL);
	}
}

int main(void) {
	// int myArray[] = {32, 12, 19, 21, 77, 31, 15, 64, 65, 18};
	int myArray[] = {77, 19, 12, 15};
	int arrayLen = sizeof(myArray) / sizeof(myArray[0]);
	int* array = malloc(sizeof(int) * arrayLen);
	for (int i = 0; i < arrayLen; i++){
		array[i] = myArray[i];
	}

	quickSort(&((qsort_arg){&array[0], &array[arrayLen]}));
	
	printf("%d, ", array[0]);
}
