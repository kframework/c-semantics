// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include<stdio.h>
#include<string.h>
#include<pthread.h>
#include<stdlib.h>



pthread_t thread_id;
pthread_mutex_t lock;

void * locker_thread(void * ptr) 
{
    pthread_mutex_unlock(&lock);
    return NULL;
}

int main(void)
{
    int err = 0;
    if (pthread_mutex_init(&lock, NULL) != 0)
    {
        printf("\n mutex init failed\n");
        return 1;
    }


   
    err = pthread_create(&thread_id, NULL, &locker_thread, NULL);
    if (err != 0) 
    {
        printf("Thread spawning error");
        return 1;
    }

   
    
    pthread_join(thread_id, NULL);
    pthread_mutex_destroy(&lock);
    
    return 0;
}
