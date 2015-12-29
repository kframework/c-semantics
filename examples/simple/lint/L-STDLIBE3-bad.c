// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <stdlib.h>
#include <stdio.h>

int main()
{
    size_t array_size = 1024 * 1024 * 1024;
    int * large_int_array = malloc(10 * sizeof(int));
    large_int_array = realloc(large_int_array, array_size * sizeof(int));
    if(large_int_array != NULL) 
    {
        free(large_int_array);
    }
}
