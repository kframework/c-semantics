#include <pthread.h>

pthread_key_t key;

int main() {
      pthread_setspecific(key, NULL);
}
