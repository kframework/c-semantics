#define NULL ((void *)0)
typedef unsigned int size_t; // this needs to correspond to cfg:sizeut
typedef int ptrdiff_t; // this needs to correspond to cfg:ptrdiffut
typedef int wchar_t;
#define offsetof(t, m) ((__kcc_offsetof(__metaType(t), __metaId(m))))
//size_t __kcc_offsetof(__metaType(type), char* member);
