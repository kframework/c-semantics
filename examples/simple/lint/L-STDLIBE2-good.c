// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <stdlib.h>
#include <stdio.h>

int main()
{
    size_t array_size = 20;
    int * small_int_array = malloc(array_size * sizeof(int));
    if(small_int_array != NULL)
    {
    
        free(small_int_array);
    }
}
