#include "2-buffer-overflow.h"

// KCC is also capable of detecting quite a wide variety of different buffer
// overflows. Seen here in this example are buffers with both internal,
// external, and no linkage, buffers with both static and automatic storage
// duration, and buffers aliased through both static- and automatic-storage
// pointers. In each case, we are able to detect the buffer overflow and print
// a stack trace on the command line of where it has occurred in the program.

/* Static */
static unsigned char	suc_array[MAX_ARRAY_SIZE];
static unsigned short	sus_array[MAX_ARRAY_SIZE];
static unsigned long	sul_array[MAX_ARRAY_SIZE];
static unsigned int		sui_array[MAX_ARRAY_SIZE];
static signed char		ssc_array[MAX_ARRAY_SIZE];
static signed short		sss_array[MAX_ARRAY_SIZE];
static signed long		ssl_array[MAX_ARRAY_SIZE];
static signed int		ssi_array[MAX_ARRAY_SIZE];

static unsigned char	*pt_suc;
static unsigned short	*pt_sus;
static unsigned long	*pt_sul;
static unsigned int		*pt_sui;
static signed char		*pt_ssc;
static signed short		*pt_sss;
static signed long		*pt_ssl;
static signed int		*pt_ssi;

int main(void)
{
	guc_Check_ABV();
	gus_Check_ABV();
	gul_Check_ABV();
	gui_Check_ABV();
	gsc_Check_ABV();
	gss_Check_ABV();
	gsl_Check_ABV();
	gsi_Check_ABV();

	suc_Check_ABV();
	sus_Check_ABV();
	sul_Check_ABV();
	sui_Check_ABV();
	ssc_Check_ABV();
	sss_Check_ABV();
	ssl_Check_ABV();
	ssi_Check_ABV();

	auc_Check_ABV();
	aus_Check_ABV();
	aul_Check_ABV();
	aui_Check_ABV();
	asc_Check_ABV();
	ass_Check_ABV();
	asl_Check_ABV();
	asi_Check_ABV();

	pt_guc_Check_ABV();
	pt_gus_Check_ABV();
	pt_gul_Check_ABV();
	pt_gui_Check_ABV();
	pt_gsc_Check_ABV();
	pt_gss_Check_ABV();
	pt_gsl_Check_ABV();
	pt_gsi_Check_ABV();

	pt_suc_Check_ABV();
	pt_sus_Check_ABV();
	pt_sul_Check_ABV();
	pt_sui_Check_ABV();
	pt_ssc_Check_ABV();
	pt_sss_Check_ABV();
	pt_ssl_Check_ABV();
	pt_ssi_Check_ABV();

	return 0;
}

/* Global Variable Case */
/* unsigned char */
void guc_Check_ABV(void)
{
	int i;
	unsigned char *pt_work;

	pt_work = &guc_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* unsigned short */
void gus_Check_ABV(void)
{
	int i;
	unsigned short *pt_work;

	pt_work = &gus_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* unsigned long */
void gul_Check_ABV(void)
{
	int i;
	unsigned long *pt_work;

	pt_work = &gul_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* unsigned int */
void gui_Check_ABV(void)
{
	int i;
	unsigned int *pt_work;

	pt_work = &gui_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* signed char */
void gsc_Check_ABV(void)
{
	int i;
	signed char *pt_work;

	pt_work = &gsc_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* signed short */
void gss_Check_ABV(void)
{
	int i;
	signed short *pt_work;

	pt_work = &gss_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* signed long */
void gsl_Check_ABV(void)
{
	int i;
	signed long *pt_work;

	pt_work = &gsl_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* singed int */
void gsi_Check_ABV(void)
{
	int i;
	signed int *pt_work;

	pt_work = &gsi_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* Static Variable Case */
void suc_Check_ABV(void)
{
	int i;
	unsigned char *pt_work;

	pt_work = &suc_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* unsigned short */
void sus_Check_ABV(void)
{
	int i;
	unsigned short *pt_work;

	pt_work = &sus_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* unsigned long */
void sul_Check_ABV(void)
{
	int i;
	unsigned long *pt_work;

	pt_work = &sul_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* unsigned int */
void sui_Check_ABV(void)
{
	int i;
	unsigned int *pt_work;

	pt_work = &sui_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* signed char */
void ssc_Check_ABV(void)
{
	int i;
	signed char *pt_work;

	pt_work = &gsc_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* signed short */
void sss_Check_ABV(void)
{
	int i;
	signed short *pt_work;

	pt_work = &sss_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* signed long */
void ssl_Check_ABV(void)
{
	int i;
	signed long *pt_work;

	pt_work = &ssl_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* singed int */
void ssi_Check_ABV(void)
{
	int i;
	signed int *pt_work;

	pt_work = &ssi_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* Auto Variable Case */
/* unsigned char */
void auc_Check_ABV(void)
{
	int i;
	unsigned char auc_array[MAX_ARRAY_SIZE];
	unsigned char *pt_work;

	pt_work = &auc_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* unsigned short */
void aus_Check_ABV(void)
{
	int i;
	unsigned short aus_array[MAX_ARRAY_SIZE];
	unsigned short *pt_work;

	pt_work = &aus_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* unsigned long */
void aul_Check_ABV(void)
{
	int i;
	unsigned long aul_array[MAX_ARRAY_SIZE];
	unsigned long *pt_work;

	pt_work = &aul_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* unsigned int */
void aui_Check_ABV(void)
{
	int i;
	unsigned int aui_array[MAX_ARRAY_SIZE];
	unsigned int *pt_work;

	pt_work = &aui_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* signed char */
void asc_Check_ABV(void)
{
	int i;
	signed char asc_array[MAX_ARRAY_SIZE];
	signed char *pt_work;

	pt_work = &asc_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* signed short */
void ass_Check_ABV(void)
{
	int i;
	signed short ass_array[MAX_ARRAY_SIZE];
	signed short *pt_work;

	pt_work = &ass_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* signed long */
void asl_Check_ABV(void)
{
	int i;
	signed long asl_array[MAX_ARRAY_SIZE];
	signed long *pt_work;

	pt_work = &asl_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* singed int */
void asi_Check_ABV(void)
{
	int i;
	signed int asi_array[MAX_ARRAY_SIZE];
	signed int *pt_work;

	pt_work = &asi_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_work = 1;
		pt_work++;
	}
}

/* Global Variable Case */
/* unsigned char */
void pt_guc_Check_ABV(void)
{
	int i;

	pt_guc = &guc_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_guc = 1;
		pt_guc++;
	}
}

/* unsigned short */
void pt_gus_Check_ABV(void)
{
	int i;

	pt_gus = &gus_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_gus = 1;
		pt_gus++;
	}
}

/* unsigned long */
void pt_gul_Check_ABV(void)
{
	int i;

	pt_gul = &gul_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_gul = 1;
		pt_gul++;
	}
}

/* unsigned int */
void pt_gui_Check_ABV(void)
{
	int i;

	pt_gui = &gui_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_gui = 1;
		pt_gui++;
	}
}

/* signed char */
void pt_gsc_Check_ABV(void)
{
	int i;

	pt_gsc = &gsc_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_gsc = 1;
		pt_gsc++;
	}
}

/* signed short */
void pt_gss_Check_ABV(void)
{
	int i;

	pt_gss = &gss_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_gss = 1;
		pt_gss++;
	}
}

/* signed long */
void pt_gsl_Check_ABV(void)
{
	int i;

	pt_gsl = &gsl_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_gsl = 1;
		pt_gsl++;
	}
}

/* singed int */
void pt_gsi_Check_ABV(void)
{
	int i;

	pt_gsi = &gsi_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_gsi = 1;
		pt_gsi++;
	}
}

/* Static Variable Case */
void pt_suc_Check_ABV(void)
{
	int i;

	pt_suc = &suc_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_suc = 1;
		pt_suc++;
	}
}

/* unsigned short */
void pt_sus_Check_ABV(void)
{
	int i;

	pt_sus = &sus_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_sus = 1;
		pt_sus++;
	}
}

/* unsigned long */
void pt_sul_Check_ABV(void)
{
	int i;

	pt_sul = &sul_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_sul = 1;
		pt_sul++;
	}
}

/* unsigned int */
void pt_sui_Check_ABV(void)
{
	int i;

	pt_sui = &sui_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_sui = 1;
		pt_sui++;
	}
}

/* signed char */
void pt_ssc_Check_ABV(void)
{
	int i;

	pt_ssc = &gsc_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_ssc = 1;
		pt_ssc++;
	}
}

/* signed short */
void pt_sss_Check_ABV(void)
{
	int i;

	pt_sss = &sss_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_sss = 1;
		pt_sss++;
	}
}

/* signed long */
void pt_ssl_Check_ABV(void)
{
	int i;

	pt_ssl = &ssl_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_ssl = 1;
		pt_ssl++;
	}
}

/* singed int */
void pt_ssi_Check_ABV(void)
{
	int i;

	pt_ssi = &ssi_array[0];

	for( i = 0; i < MAX_LOOP_CNT; i++ )
	{
		*pt_ssi = 1;
		pt_ssi++;
	}
}
