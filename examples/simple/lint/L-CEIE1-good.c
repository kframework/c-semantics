#include <stdlib.h>
#include <stdio.h>

int main()
{
    int * number_ptr = malloc(sizeof(int));
    *number_ptr = 10;
    free(number_ptr);
    printf("No memory Leaks, Execution Successful\n");
}
