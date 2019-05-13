#include<cstdio>
class Buffer {
public:
  virtual int size() = 0;

  virtual char &elem(int idx) = 0;
};

#define ARRAY_SIZE 10

class ArrayBuffer : public Buffer {
  char buf[ARRAY_SIZE];
  int id;
public:
  int size() override {
    return sizeof(buf);
  }

  char &elem(int idx) override {
    return buf[idx];
  }

  ArrayBuffer(int id) : buf{}, id(id) {}
};

class DynamicBuffer : public Buffer {
  char *buf;
  int _size;
public:
  int size() override {
    return _size;
  }

  char &elem(int idx) override {
    return buf[idx];
  }

  DynamicBuffer(int size) : buf(new char[size]), _size(size) {}
};

Buffer *makeBuffer(char *arr, int size) {
  if (size > ARRAY_SIZE) {
    Buffer *buf = new DynamicBuffer(size);
    for (int i = 0; i < size; i++) {
      buf->elem(i) = arr[i];
    }
    return buf;
  } else {
    Buffer *buf = new ArrayBuffer(1);
    for (int i = 0; i < size; i++) {
      buf->elem(i) = arr[i];
    } 
    return buf;
  }
}

int main() {
  char arr[12] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};
  Buffer *buf = makeBuffer(arr, sizeof(arr));
  Buffer *arrBuf = new ArrayBuffer(0);
  for (int i = 0; i < buf->size(); i++) {
    arrBuf->elem(i) = buf->elem(i);
  }
  for (int i = 0; i < arrBuf->size(); i++) {
    printf("%d ", arrBuf->elem(i));
  }
  printf("\n");
}
