// KCC is also capable of detecting quite a wide variety of different buffer
// overflows. Seen here in this example borrowed from the Toyota ITC benchmark
// (see ISSRE'15 paper by Shiraishi etal) are a wide variety of buffers that
// are allocated dynamically and accessed in a variety of different ways.
// In each case, we are able to detect the buffer overflow and print
// a stack trace on the command line of where it has occurred in the program.

// Copyright (c) 2012-2014 Toyota InfoTechnology Center, U.S.A. Inc.
// Modified under terms of BSD license, reproduced below:
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
//   * Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//   * Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in the
//     documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include<stdlib.h>
#include<stdio.h>
#include<string.h>

void dynamic_buffer_overrun_001 ()
{
	char *buf=(char*) calloc(5,sizeof(char));
	int i;
	if(buf!=NULL)
	{
		for (i=0;i<=5;i++)
	    {
			buf[i]=1; /*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    }
	    free(buf);
	}
}

/*
 * Dynamic buffer overrun
 *When using a pointer to short
 */
void dynamic_buffer_overrun_002 ()
{
	short *buf=(short*) calloc(5,sizeof(short));
	if(buf!=NULL)
	{
		*(buf+5)=1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
		free(buf);
	}
}

/*
 * Dynamic buffer overrun
 *When using a pointer to int
 */
void dynamic_buffer_overrun_003 ()
{
	int *buf=(int*) calloc(5,sizeof(int));
	int ret;
	int i;
	if(buf!=NULL)
	{
		for (i=0;i<5;i++)
		{
			buf[i]=1;
		}
		ret = buf[5];/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
		free(buf);
		printf("%d",ret);
	}
}

/*
 * Dynamic buffer overrun
 *When using a pointer to int
 */
void dynamic_buffer_overrun_004 ()
{
	int *buf=(int*) calloc(5,sizeof(int));
	if(buf!=NULL)
	{
		*(buf+5) = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
		free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * When using a pointer to long
 */
void dynamic_buffer_overrun_005 ()
{
	long *buf=(long*) calloc(5,sizeof(long));
	int i;
	if(buf!=NULL)
	{
		for(i=0;i<=5;i++)
		{
			buf[i]=1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
		}
		free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * When using a pointer to float
 */
void dynamic_buffer_overrun_006 ()
{
	float *buf=(float*) calloc(5,sizeof(float));
	int i;
	if(buf!=NULL)
	{
		for(i=0;i<=5;i++)
		{
			buf[i]=1.0;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
		}
	    free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * When using a pointer to float
 */
void dynamic_buffer_overrun_007 ()
{
	double *buf=(double*) calloc(5,sizeof(double));
	int i;
	if(buf!=NULL)
	{
		for(i=0;i<=5;i++)
		{
			buf[i]=1.0;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
		}
	    free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * When using double pointers to the type int
 */
void dynamic_buffer_overrun_008 ()
{
	int **buf = (int**) calloc(5,sizeof(int*));
	int i,j;

	for(i=0;i<5;i++)
		buf[i]=(int*) calloc(5,sizeof(int));

	for(i=0;i<5;i++)
	{
		for(j=0;j<=5;j++)
		{
			*(*(buf+i)+j)=i;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
		}
		free(buf[i]);
	}
	free(buf);
}

/*
 * Dynamic buffer overrun
 * When using double pointers to the type int
 */
void dynamic_buffer_overrun_009 ()
{
	int *buf1=(int*)calloc(5,sizeof(int));
	int *buf2=(int*)calloc(5,sizeof(int));
	int *buf3=(int*)calloc(5,sizeof(int));
	int *buf4=(int*)calloc(5,sizeof(int));
	int *buf5=(int*)calloc(5,sizeof(int));
	int **pbuf[5] = {&buf1, &buf2, &buf3, &buf4, &buf5};
	int i,j=6;
	for(i=0;i<5;i++)
	{
		*((*pbuf[i])+j)=5;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	}
	free(buf1);
	free(buf2);
	free(buf3);
	free(buf4);
	free(buf5);
}

/*
 * Dynamic buffer overrun
 * When using pointers to the structure
 */
typedef struct {
	int a;
	int b;
	int c;
} dynamic_buffer_overrun_010_s_001;

void dynamic_buffer_overrun_010 ()
{
	dynamic_buffer_overrun_010_s_001* sbuf= calloc(5,sizeof(dynamic_buffer_overrun_010_s_001)) ;
	if(sbuf!=NULL)
	{
	    sbuf[5].a = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    free(sbuf);
	}
}

/*
 * Dynamic buffer overrun
 * When using pointers to the structure with an array as a member of the structure
 */
typedef struct {
	int a;
	int b;
	int buf[5];
} dynamic_buffer_overrun_011_s_001;

void dynamic_buffer_overrun_011 ()
{
	dynamic_buffer_overrun_011_s_001* s=(dynamic_buffer_overrun_011_s_001*) calloc(5,sizeof(dynamic_buffer_overrun_011_s_001)) ;
	if(s!=NULL)
	{
		(s+5)->buf[4] = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
		free(s);
	}
}

/*
 * Dynamic buffer overrun
 * When using a variable to access the array of pointers
 */
void dynamic_buffer_overrun_012 ()
{
	int *buf=(int*) calloc(5,sizeof(int));
	int index = 5;
	if(buf!=NULL)
	{
		*(buf+index)=9;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
		free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * When using a variable which changes on every iteration to access the array of pointers
 */
void  dynamic_buffer_overrun_013()
{
	int *buf=(int*) calloc(5,sizeof(int));
	int index = 5;
	if(buf!=NULL)
	{
	    buf[index] = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * When performing arithmetic operations on the index variable causing it to go out of bounds.
 */
void dynamic_buffer_overrun_014 ()
{
	int *buf=(int*) calloc(5,sizeof(int));
	int index = 3;
	if(buf!=NULL)
	{
	    *(buf +((2 * index) + 1)) = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * When performing arithmetic operations on the index variable causing it to go out of bounds.
 */
void dynamic_buffer_overrun_015 ()
{
	int *buf=(int*) calloc(5,sizeof(int));
	int index = 2;
	if(buf!=NULL)
	{
	    buf[(index * index) + 1] = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * When using a return value from a function to access memory
 */

int dynamic_buffer_overrun_016_func_001 ()
{
	return 5;
}

void dynamic_buffer_overrun_016 ()
{
	int *buf=(int*) calloc(5,sizeof(int));
	if(buf!=NULL)
	{
	    buf[dynamic_buffer_overrun_016_func_001 ()] = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * overrun in the function called
 */
void dynamic_buffer_overrun_017_func_001 (int index)
{
	int *buf=(int*) calloc(5,sizeof(int));
	if(buf!=NULL)
	{
	    *(buf +index) = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    free(buf);
	}
}

void dynamic_buffer_overrun_017 ()
{
	dynamic_buffer_overrun_017_func_001(5);
}

/*
 * Dynamic buffer overrun
 * overrun in when using member of some other array as the index
 */
void dynamic_buffer_overrun_018 ()
{
	int *buf=(int*) calloc(5,sizeof(int));
	int indexes[4] = {3, 4, 5, 6};
	int index = 4;
	if(buf!=NULL)
	{
	    *(buf+indexes[index]) = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * overrun when using a variable assigned by some other variable
 */
void dynamic_buffer_overrun_019 ()
{
	int *buf=(int*) calloc(5,sizeof(int));
	int index = 5;
	int index1;
	index1 = index;
	if(buf!=NULL)
	{
	    buf[index1] = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * overrun when using 2 aliases
 */
void dynamic_buffer_overrun_020 ()
{
	int *buf=(int*) calloc(5,sizeof(int));
	int index = 5;
	int index1;
	int index2;
	index1 = index;
	index2 = index1;
	if(buf!=NULL)
	{
	    buf[index2] = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * overrun when using 2 pointer aliases
 */
void dynamic_buffer_overrun_021 ()
{
	int *buf=(int*) calloc(5,sizeof(int));
	int *p1;
	int *p2;
	if(buf!=NULL)
	{
		p1 = buf;
		p2 = p1;
		*(p2+5) = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * overrun when using 1 single pointer alias
 */
void dynamic_buffer_overrun_022 ()
{
	int *buf=(int*) calloc(5,sizeof(int));
	int *p;
	if(buf!=NULL)
	{
	    p = buf;
	    *(p+5) = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * overrun IN A FOR LOOP
 */
void dynamic_buffer_overrun_023 ()
{
	int *buf=(int*) calloc(5,sizeof(int));
	int *p;
	int i;
	if(buf!=NULL)
	{
	    p = buf;
	    for (i = 0; i <= 5; i ++)
	    {
		    *p = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
		     p ++;
	    }
	    free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * overrun when passing the base pointer to a function
 */
void dynamic_buffer_overrun_024_func_001 (int *buf)
{
	*(buf+5) = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
}

void dynamic_buffer_overrun_024 ()
{
	int *buf=(int*) calloc(5,sizeof(int));

	dynamic_buffer_overrun_024_func_001(buf);
	if(buf!=NULL)
	{
	    free(buf);
	}
}


/*
 * Dynamic buffer overrun
 * overrun when using a char pointer
 */
void dynamic_buffer_overrun_025 ()
{
	char *buf=(char*) calloc(5,sizeof(char));
	int i;
	if(buf!=NULL)
	{
		for(i=0;i<=5;i++)
		{
			buf[i]='1';/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
		}
	    free(buf);
	}
}


/*
 * Dynamic buffer overrun
 * overrun when using casting to pointers of larger datatypes (For eg Cast a char to int)
 */
void dynamic_buffer_overrun_026 ()
{
	char *buf=(char*) calloc(5,sizeof(char));
	int *p;
	p = (int*)buf;
	if(buf!=NULL)
	{
	    *(p + 5) = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * overrun when using casting to pointers of smaller datatypes (For eg Cast a int to char)
 */
void dynamic_buffer_overrun_027 ()
{
	int *buf=(int*) calloc(5,sizeof(int));
	char *p;
	p = (char*)buf;
	if(buf!=NULL)
	{
	    *(p + 30) = 1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    free(buf);
	}
}

/*
 * Dynamic buffer overrun
 * overrun when using values in a different array allocated dynamically
 */
void dynamic_buffer_overrun_028 ()
{
	int *buf1=(int*) calloc(5,sizeof(int));
	int *buf2=(int*) calloc(3,sizeof(int));
	int i;
	    for(i=0;i<5;i++)
		{
	    	*(buf1+i)=i;
		}
    	*(buf2+*(buf1+5))=1;/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    free(buf1);
	    free(buf2);
}

/*
 * Dynamic buffer overrun
 * overrun in while loop
 */
void dynamic_buffer_overrun_029()
{

	int i=1;
	while (i)
	{
		char* buf= (char*) malloc(sizeof(char));
		if(buf!=NULL)
		{
		    buf[i+1]='a';/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
		    free(buf);
		}
		i--;
	}
}


/* Types of defects: heap overrun(dynamic buffer overrun)
* Complexity: ---- Write outside the allocated buffer in a 2D array
*/

void dynamic_buffer_overrun_030()
{
	int i,j;
	char ** doubleptr=(char**) malloc(10*sizeof(char*));

	for(i=0;i<10;i++)
	{
		doubleptr[i]=(char*) malloc(10*sizeof(char));
	}


	for(i=0;i<10;i++)
	{
		for(j=0;j<=10;j++)
		{
		  doubleptr[i][j]='a';    	/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
		}
		free(doubleptr[i]);
	}	
	free(doubleptr);
}

/* Types of defects: heap overrun(dynamic buffer overrun)
* Complexity: ---- overrun while using memcpy function
*/

void dynamic_buffer_overrun_031()
{
	int i;
	char* ptr1=(char*) calloc(12, sizeof(char));
	char a[12],*ptr2 = a;

	if(ptr1!=NULL)
	{
	    for(i=0;i<=12;i++)
	    {
	    	ptr1[i]='a';/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*/
	    }
    	ptr1[11]='\0';
	    memcpy(ptr2,ptr1,12);//vm
	    free(ptr1);
	}
}

/* Types of defects: heap overrun(dynamic buffer overrun)
* Complexity: ---- overrun when using a structure
*/


typedef struct
{
	char arr[10];
	int arri[10];
}dynamic_buffer_overrun_s_005;

void dynamic_buffer_overrun_032()
{	
	dynamic_buffer_overrun_s_005* ptr_s= malloc(10*sizeof(dynamic_buffer_overrun_s_005));
	int i;
	if(ptr_s!=NULL)
	{
	    for(i=0;i<=10;i++)
	    {
	    	ptr_s[i].arr[i]='a';/*Tool should detect this line as error*/ /*ERROR:Buffer overrun*///vm - Changed arri(int) to arr(char);
	    }
	    free(ptr_s);
	}
}

/* Types of defects: heap overrun(dynamic buffer overrun)
*  dynamic buffer overrun main - Function call
*/
int main ()
{
		dynamic_buffer_overrun_001();

		dynamic_buffer_overrun_002();

		dynamic_buffer_overrun_003();

		dynamic_buffer_overrun_004();

		dynamic_buffer_overrun_005();

		dynamic_buffer_overrun_006();

		dynamic_buffer_overrun_007();

		dynamic_buffer_overrun_008();

		dynamic_buffer_overrun_009();

		dynamic_buffer_overrun_010();

		dynamic_buffer_overrun_011();

		dynamic_buffer_overrun_012();

		dynamic_buffer_overrun_013();

		dynamic_buffer_overrun_014();

		dynamic_buffer_overrun_015();

		dynamic_buffer_overrun_016();

		dynamic_buffer_overrun_017();

		dynamic_buffer_overrun_018();

		dynamic_buffer_overrun_019();

		dynamic_buffer_overrun_020();

		dynamic_buffer_overrun_021();

		dynamic_buffer_overrun_022();

		dynamic_buffer_overrun_023();

		dynamic_buffer_overrun_024();

		dynamic_buffer_overrun_025();

		dynamic_buffer_overrun_026();

		dynamic_buffer_overrun_027();

		dynamic_buffer_overrun_028();

		dynamic_buffer_overrun_029();

		dynamic_buffer_overrun_030();

		dynamic_buffer_overrun_031();

		dynamic_buffer_overrun_032();
}
