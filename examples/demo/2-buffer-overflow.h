/* sample.h */

/* macro */
#define MAX_ARRAY_SIZE	(3)
#define MAX_LOOP_CNT	(5)

void guc_Check_ABV(void);
void gus_Check_ABV(void);
void gul_Check_ABV(void);
void gui_Check_ABV(void);
void gsc_Check_ABV(void);
void gss_Check_ABV(void);
void gsl_Check_ABV(void);
void gsi_Check_ABV(void);
void suc_Check_ABV(void);
void sus_Check_ABV(void);
void sul_Check_ABV(void);
void sui_Check_ABV(void);
void ssc_Check_ABV(void);
void sss_Check_ABV(void);
void ssl_Check_ABV(void);
void ssi_Check_ABV(void);
void auc_Check_ABV(void);
void aus_Check_ABV(void);
void aul_Check_ABV(void);
void aui_Check_ABV(void);
void asc_Check_ABV(void);
void ass_Check_ABV(void);
void asl_Check_ABV(void);
void asi_Check_ABV(void);

void pt_guc_Check_ABV(void);
void pt_gus_Check_ABV(void);
void pt_gul_Check_ABV(void);
void pt_gui_Check_ABV(void);
void pt_gsc_Check_ABV(void);
void pt_gss_Check_ABV(void);
void pt_gsl_Check_ABV(void);
void pt_gsi_Check_ABV(void);
void pt_suc_Check_ABV(void);
void pt_sus_Check_ABV(void);
void pt_sul_Check_ABV(void);
void pt_sui_Check_ABV(void);
void pt_ssc_Check_ABV(void);
void pt_sss_Check_ABV(void);
void pt_ssl_Check_ABV(void);
void pt_ssi_Check_ABV(void);

/* Global Variable */
unsigned char	guc_array[MAX_ARRAY_SIZE];
unsigned short	gus_array[MAX_ARRAY_SIZE];
unsigned long	gul_array[MAX_ARRAY_SIZE];
unsigned int	gui_array[MAX_ARRAY_SIZE];
signed char		gsc_array[MAX_ARRAY_SIZE];
signed short	gss_array[MAX_ARRAY_SIZE];
signed long		gsl_array[MAX_ARRAY_SIZE];
signed int		gsi_array[MAX_ARRAY_SIZE];

unsigned char	*pt_guc;
unsigned short	*pt_gus;
unsigned long	*pt_gul;
unsigned int	*pt_gui;
signed char		*pt_gsc;
signed short	*pt_gss;
signed long		*pt_gsl;
signed int		*pt_gsi;
