// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include<pthread.h>
#include<stdlib.h>


pthread_mutex_t * lock_ptr;


int main(void)
{
    //Calling pthread_mutex_lock without a call to pthread_mutex_init
    lock_ptr = malloc(sizeof(pthread_mutex_t));
    pthread_mutex_trylock(lock_ptr);
    
    return 0;
}
