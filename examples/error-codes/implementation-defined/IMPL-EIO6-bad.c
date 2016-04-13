#include<pthread.h>
#include<stdlib.h>

void *foo(void *arg) {
  int *bar = arg;
  *bar;
  return NULL;
}

int main() {
  pthread_t thr;
  int x = 0;
  pthread_create(&thr, NULL, foo, &x);
  pthread_join(thr, NULL);
}
