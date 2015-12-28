// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

pthread_mutex_t lock;

int main(void)
{
    
    pthread_mutex_init(&lock, NULL);
    pthread_mutex_lock(&lock);
    pthread_mutex_unlock(&lock);
    pthread_mutex_destroy(&lock);
    printf("Successful Execution\n");
    return 0;
}
