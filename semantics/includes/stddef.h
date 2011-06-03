typedef int ptrdiff_t; // this needs to correspond to cfg:ptrdiffut
typedef unsigned int size_t; // this needs to correspond to cfg:sizeut
typedef char max_align_t;
typedef int wchar_t;

#define NULL ((void *)0)
#define offsetof(t, m) ((__kcc_offsetof((t), (m))))
