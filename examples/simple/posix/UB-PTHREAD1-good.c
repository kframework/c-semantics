// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
pthread_mutex_t lock;

int main(void)
{

    if (pthread_mutex_init(&lock, NULL) != 0)
    {
        printf("\n First Initialization of mutex failed\n");
        return 1;
    }
    
    pthread_mutex_destroy(&lock);
    
    printf("Correct Execution");
    
    return 0;
}
