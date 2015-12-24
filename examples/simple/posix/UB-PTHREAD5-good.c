// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <string.h>
#include <stdio.h>
#include <pthread.h>
#include <stdlib.h>


pthread_mutex_t lock;


int main(void)
{
    //Calling pthread_mutex_lock without a call to pthread_mutex_init
    pthread_mutex_init(&lock, NULL);
    pthread_mutex_lock(&lock);
    
    pthread_mutex_unlock(&lock);
    
    pthread_mutex_destroy(&lock);
    
    printf("Succesful Execution\n"); 
    
    return 0;
}
