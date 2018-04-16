#include <pthread.h>

pthread_mutex_t mut;
int var1;
int var2;

void * thread1(void * p) {
      pthread_mutex_lock(&mut);
      var2 = 1;
      pthread_mutex_unlock(&mut);

      for (;;) {
            pthread_mutex_lock(&mut);
            int v = var1;
            pthread_mutex_unlock(&mut);

            if (v) return NULL;
      }
}

void * thread2(void * p) {
      pthread_mutex_lock(&mut);
      var1 = 1;
      pthread_mutex_unlock(&mut);

      for (;;) {
            pthread_mutex_lock(&mut);
            int v = var2;
            pthread_mutex_unlock(&mut);

            if (v) return NULL;
      }
}

int main() {
      pthread_t th1, th2;

      pthread_mutex_init(&mut, NULL);

      pthread_create(&th1, NULL, thread1, NULL);
      pthread_create(&th2, NULL, thread2, NULL);

      pthread_join(th1, NULL);
      pthread_join(th2, NULL);
}
