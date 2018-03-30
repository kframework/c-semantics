#include <pthread.h>

int main() {
      pthread_key_t key;
      pthread_key_create(&key, NULL);
}
