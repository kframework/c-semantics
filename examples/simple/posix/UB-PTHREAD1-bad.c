// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <stdio.h>
#include <pthread.h>
#include <stdlib.h>


pthread_mutex_t lock;

int main(void)
{
    if (pthread_mutex_init(&lock, NULL) != 0)
    {
        printf("\n First initialization of mutex failed\n");
        return 1;
    }
    pthread_mutex_init(&lock, NULL);
    pthread_mutex_destroy(&lock);
    return 0;
}
