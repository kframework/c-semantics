#include <stdio.h>

#define QSIZE 16

#if ((QSIZE)<2)||(!((((QSIZE)|((QSIZE)-1))+1)/2==(QSIZE)))
#error QSIZE must be >1 and also a power of 2
#endif

#define MASK ((QSIZE)-1)

static int q[QSIZE];

static int head, tail;

static int
inc (int x)
{
  return (x + 1) & MASK;
}

int
full (void)
{
  return inc (head) == tail;
}

int
mt (void)
{
  return head == tail;

}

int
enq (int item)
{
  if (full ())
    return 0;
  q[head] = item;
  head = inc (head);
  return 1;
}

int
deq (int *loc)
{
  if (mt ())
    return 0;
  *loc = q[tail];

  tail = inc (tail);
  return 1;
}

int
qents (void)
{
  int s = head - tail;
  if (s < 0)
  s += (QSIZE);
  return s;
}


void printdeq(void) {
	int item=0;
	int res = deq (&item);	
	printf("%d, %d\n", res, item);
}

int main(void) {
	printf("emtpy==%d\n", mt());
	printf("full==%d\n", full());
	for (int i = 0; i < QSIZE; i++){
		enq(i*2);
	}
	printf("emtpy==%d\n", mt());
	printf("full==%d\n", full());
	printf("qents==%d\n", qents());
	for (int i = 0; i < QSIZE/2; i++){
		printdeq();
	}
	printf("emtpy==%d\n", mt());
	printf("full==%d\n", full());
	printf("qents==%d\n", qents());
	for (int i = 0; i < QSIZE/2; i++){
		enq(i*2);
	}
	printf("emtpy==%d\n", mt());
	printf("full==%d\n", full());
	printf("qents==%d\n", qents());
	while (!mt()){
		printdeq();
	}
	printdeq();
}
