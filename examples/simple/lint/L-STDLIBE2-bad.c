// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <stdlib.h>
#include <stdio.h>

int main()
{
    int array_size = 1024 * 1024 * 1024;
    int * large_int_array = malloc(array_size * sizeof(int));
    if(large_int_array != NULL) 
    {
        free(large_int_array);
    }
}
