#include<pthread.h>
#include<stdlib.h>

void *foo(void *arg) {
  int *bar = arg;
  *bar = 5;
  return NULL;
}

int main() {
  pthread_t thr;
  int *x = malloc(sizeof(int));
  pthread_create(&thr, NULL, foo, x);
  pthread_join(thr, NULL);
}
