#define SAVEt_ITEM	0
#define SAVEt_SV	1
#define SAVEt_AV	2
#define SAVEt_HV	3
#define SAVEt_INT	4
#define SAVEt_I32	5
#define SAVEt_SPTR	6
#define SAVEt_HPTR	7
#define SAVEt_APTR	8
#define SAVEt_NSTAB	9
#define SAVEt_SVREF	10
#define SAVEt_GP	11

#define SSCHECK(need) if (savestack_ix + need > savestack_max) savestack_grow()
#define SSPUSHINT(i) (savestack[savestack_ix++].any_i32 = (I32)(i))
#define SSPUSHPTR(p) (savestack[savestack_ix++].any_ptr = (void*)(p))
#define SSPOPINT (savestack[--savestack_ix].any_i32)
#define SSPOPPTR (savestack[--savestack_ix].any_ptr)
