#include <pthread.h>

void* thread(void* arg) {
      return arg;
}

int main(void) {
      pthread_t tid1, tid2;
      pthread_create(&tid1, NULL, thread, NULL);
      pthread_create(&tid2, NULL, thread, NULL);
      pthread_join(tid1, NULL);
      pthread_join(tid2, NULL);
}
