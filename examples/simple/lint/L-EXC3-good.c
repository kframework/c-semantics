// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <stdlib.h>
#include <stdio.h>

int retval;
void * func()
{
    return &retval; 
}

int main()
{
    void * (*func_ptr)() = &func;
    if(func_ptr() != NULL)
    {
       printf("Hello, World!\n"); 
        
    }
    
}
