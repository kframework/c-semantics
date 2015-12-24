// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <stdlib.h>
#include <stdio.h>

void func(int number)
{
    printf("func called with number: %i\n", number);
}

int main()
{
    void (*func_ptr)(int) = &func;
    if(func_ptr == &func)
    {
        func(1);
        
    }
    
}
