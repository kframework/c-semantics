#include<stdint.h>

#include "platform.h"
#include "server.h"
#include "symbols.c"

#ifndef NATIVE_MEMORY_SIZE
#define NATIVE_MEMORY_SIZE 8192
#endif

static __native_mem_t native_memory[NATIVE_MEMORY_SIZE];
static char dirty_buffer[8192];

static void write_dirty(char *ptr, short len) {
  short i;
  for (i = 0; i < len; i++, ptr++) {
    if (*ptr != dirty_buffer[i]) {
      *ptr = dirty_buffer[i];
    }
  }
}

static void invoke(void) {
  uint32_t len, remaining;
  int64_t address;

  __recv_message(&address, sizeof(address));
  __trampoline_t trampoline = (__trampoline_t) (intptr_t)address;
  __recv_message(&address, sizeof(address));
  void (*fptr)() = (void (*)())(intptr_t)address;
  __recv_message(&address, sizeof(address));
  void *retval = (void *)(intptr_t)address;
  __recv_message(&len, sizeof(len));
  if (len > NATIVE_MEMORY_SIZE) {
    __error("buffer too small to contain native memory");
  }
  int32_t i;
  int32_t size_native_memory = len;
  for (i = 0; i < size_native_memory; i++) {
    __recv_message(&address, sizeof(address));
    native_memory[i].address = (void *)(intptr_t)address;
    char is_dirty;
    __recv_message(&is_dirty, sizeof(is_dirty));
    __recv_message(&len, sizeof(len));
    native_memory[i].size = len;
    if (is_dirty) {
      remaining = len;
      char *ptr = native_memory[i].address;
      while (remaining > sizeof(dirty_buffer)) {
        __recv_message(dirty_buffer, sizeof(dirty_buffer));
        write_dirty(ptr, sizeof(dirty_buffer));
        remaining -= sizeof(dirty_buffer);
        ptr += sizeof(dirty_buffer);
      }
      __recv_message(dirty_buffer, remaining);
      write_dirty(ptr, remaining);
    } else {
      __recv_message(native_memory[i].address, len);
    }
  }
  trampoline(fptr, retval);
  __send_message(&size_native_memory, sizeof(size_native_memory));
  for (i = 0; i < size_native_memory; i++) {
    len = native_memory[i].size;
    address = (int64_t)(intptr_t)native_memory[i].address;
    __send_message(&len, sizeof(len));
    __send_message(native_memory[i].address, len);
    __send_message(&address, sizeof(address));
  }
}

static void get_symbol_table(void) {
  size_t nsymbols = sizeof(symbols) / sizeof(symbols[0]);
  size_t i;
  int32_t len;
  int64_t address;

  len = nsymbols;
  __send_message(&len, sizeof(len));
  for (i = 0; i < nsymbols; i++) {
    __symbol_t *sym = symbols + i;
    len = strlen(sym->name);
    __send_message(&len, sizeof(len));
    __send_message(sym->name, len);
    address = (int64_t)(intptr_t)sym->addr;
    __send_message(&address, sizeof(address));
  }
}

static void alloc(void) {
  int64_t size_param;
  int64_t address;
  __recv_message(&size_param, sizeof(size_param));
  size_t size = size_param;
  void *ptr = __alloc(size);
  address = (int64_t)(intptr_t)ptr;
  __send_message(&address, sizeof(address));
}

static void sync_read(void) {
  int64_t address;
  __recv_message(&address, sizeof(address));
  int32_t size_param;
  __recv_message(&size_param, sizeof(size_param));
  size_t size = size_param;
  void *ptr = (void *)(intptr_t)address;
  __send_message(ptr, size);
}

void __server(const char *read_path, const char *write_path) {
  __init_messages(read_path, write_path);

  while (1) {
    char opcode;
    __recv_message(&opcode, sizeof(opcode));
    __cmd_t cmd = opcode;
    char exited = 0;
    switch(cmd) {
    case _INVOKE:
      invoke();
      break;
    case _GET_SYMBOL_TABLE:
      get_symbol_table();
      break;
    case _ALLOC:
      alloc();
      break;
    case _SYNC_READ:
      sync_read();
      break;
    case _EXIT:
      __send_message("", 1);
      exited = 1;
      break;
    default:
      __error("undefined command");
      break;
    }
    __flush_message();
    if (exited) {
      break;
    }
  }
  __deinit_messages();
}
