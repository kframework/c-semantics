// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include<stdio.h>
#include<string.h>
#include<pthread.h>
#include<stdlib.h>


pthread_mutex_t lock;


int main(void)
{
    pthread_mutex_init(&lock, NULL);
    pthread_mutex_destroy(&lock);
    
    printf("Successful Execution \n");
    
    return 0;
}
