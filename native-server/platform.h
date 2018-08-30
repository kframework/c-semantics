#ifndef PLATFORM_H
#define PLATFORM_H

#include<stddef.h>

/* Connects to the RV-Match client process, optionally accepting a pair of file
 * system paths pointing to named pipes. Implementations that do not have a
 * file system are free to pass whatever values they want to this function. */
void __init_messages(const char *read_path, const char *write_path);

/* sends a message of length len contained in the buffer buf. Guaranteed to
 * send exactly len characters. */
void __send_message(void *buf, size_t len);

/* Receives a message and copies len characters into the buffer buf.
 * Guaranteed to receive exactly len characters. */
void __recv_message(void *buf, size_t len);

/* Performs cleanup to terminate the native call server and free resources. */
void __deinit_messages(void);

/* Handles an error that arises during execution of platform-independent code. */
void __error(char *msg);

/* Allocates a native buffer of a particular size. */
void *__alloc(size_t size);

void __flush_message(void);

int strcmp(const char *s1, const char *s2);
size_t strlen(const char *s);

#endif
