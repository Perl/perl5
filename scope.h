#define SAVEt_ITEM	0
#define SAVEt_SV	1
#define SAVEt_AV	2
#define SAVEt_HV	3
#define SAVEt_INT	4
#define SAVEt_LONG	5
#define SAVEt_I32	6
#define SAVEt_SPTR	7
#define SAVEt_APTR	8
#define SAVEt_HPTR	9
#define SAVEt_PPTR	10
#define SAVEt_NSTAB	11
#define SAVEt_SVREF	12
#define SAVEt_GP	13
#define SAVEt_FREESV	14
#define SAVEt_FREEOP	15
#define SAVEt_FREEPV	16
#define SAVEt_CLEARSV	17
#define SAVEt_DELETE	18

#define SSCHECK(need) if (savestack_ix + need > savestack_max) savestack_grow()
#define SSPUSHINT(i) (savestack[savestack_ix++].any_i32 = (I32)(i))
#define SSPUSHLONG(i) (savestack[savestack_ix++].any_long = (long)(i))
#define SSPUSHPTR(p) (savestack[savestack_ix++].any_ptr = (void*)(p))
#define SSPOPINT (savestack[--savestack_ix].any_i32)
#define SSPOPLONG (savestack[--savestack_ix].any_long)
#define SSPOPPTR (savestack[--savestack_ix].any_ptr)

#define FREE_TMPS() if (tmps_ix > tmps_floor) free_tmps()
#define LEAVE_SCOPE(old) if (savestack_ix > old) leave_scope(old)
