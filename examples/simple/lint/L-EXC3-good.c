// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <stdlib.h>
#include <stdio.h>

void * func()
{
    int * retval = malloc(sizeof(int));
    *retval = 1;
    return retval; 
}

int main()
{
    void * (*func_ptr)() = &func;
    if(func_ptr() != NULL)
    {
       printf("Hello, World!\n"); 
        
    }
    
}
