// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <pthread.h>
#include <stdlib.h>
#include <string.h>


int main(void)
{
    
    pthread_mutex_t lock;
    pthread_mutex_t lock_cpy;
    pthread_mutex_init(&lock, NULL);
    memcpy(&lock_cpy, &lock, sizeof(pthread_mutex_t)); 
    pthread_mutex_lock(&lock_cpy);
    return 0;
}
