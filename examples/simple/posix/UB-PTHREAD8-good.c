// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include<pthread.h>
#include<stdlib.h>


pthread_mutex_t lock;


int main(void)
{
    pthread_mutex_init(&lock);
    pthread_mutex_trylock(&lock);
    pthread_mutex_unlock(&lock);
    pthread_mutex_destroy(&lock);
    return 0;
}
