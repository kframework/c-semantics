#ifndef SERVER_H
#define SERVER_H

void __server(const char *read_path, const char *write_path);

typedef enum {
  _INVOKE = 0,
  _GET_SYMBOL_TABLE = 1,
  _ALLOC = 2,
  _SYNC_READ = 3,
  _EXIT = 4
} __cmd_t;

typedef void (*__trampoline_t)(void (*fptr)(), void *retval);

typedef struct {
  void *address;
  size_t size;
} __native_mem_t;

typedef struct {
  char *name;
  void (*addr)();
} __symbol_t;

#endif
