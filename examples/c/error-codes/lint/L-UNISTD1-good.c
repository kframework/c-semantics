#include <pthread.h>
#include <unistd.h>

pthread_mutex_t lock;

int main() {
    if (pthread_mutex_init(&lock, NULL) != 0)
    {
        printf("\n First initialization of mutex failed\n");
        return 1;
    }
    pthread_mutex_lock(&lock);
    pthread_mutex_unlock(&lock);
}
