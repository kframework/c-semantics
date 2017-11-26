#include <signal.h>
#include <pthread.h>

void handler(int sig) { return; }

void* thread(void* arg) { return NULL; }

int main(void) {
      pthread_t thid;
      pthread_create(&thid, NULL, thread, NULL);

      signal(SIGUSR1, handler);

      pthread_join(thid, NULL);
}
