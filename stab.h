/* $Header: stab.h,v 3.0 89/10/18 15:23:30 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	stab.h,v $
 * Revision 3.0  89/10/18  15:23:30  lwall
 * 3.0 baseline
 * 
 */

struct stabptrs {
    char        stbp_magic[4];
    STR		*stbp_val;	/* scalar value */
    struct stio *stbp_io;	/* filehandle value */
    FCMD	*stbp_form;	/* format value */
    ARRAY	*stbp_array;	/* array value */
    HASH	*stbp_hash;	/* associative array value */
    SUBR	*stbp_sub;	/* subroutine value */
    int		stbp_lastexpr;	/* used by nothing_in_common() */
    line_t	stbp_line;	/* line first declared at (for -w) */
    char	stbp_flags;
};

#define stab_magic(stab)	(((STBP*)(stab->str_ptr))->stbp_magic)
#define stab_val(stab)		(((STBP*)(stab->str_ptr))->stbp_val)
#define stab_io(stab)		(((STBP*)(stab->str_ptr))->stbp_io)
#define stab_form(stab)		(((STBP*)(stab->str_ptr))->stbp_form)
#define stab_xarray(stab)	(((STBP*)(stab->str_ptr))->stbp_array)
#define stab_array(stab)	(((STBP*)(stab->str_ptr))->stbp_array ? \
				 ((STBP*)(stab->str_ptr))->stbp_array : \
				 ((STBP*)(aadd(stab)->str_ptr))->stbp_array)
#define stab_xhash(stab)	(((STBP*)(stab->str_ptr))->stbp_hash)
#define stab_hash(stab)		(((STBP*)(stab->str_ptr))->stbp_hash ? \
				 ((STBP*)(stab->str_ptr))->stbp_hash : \
				 ((STBP*)(hadd(stab)->str_ptr))->stbp_hash)
#define stab_sub(stab)		(((STBP*)(stab->str_ptr))->stbp_sub)
#define stab_lastexpr(stab)	(((STBP*)(stab->str_ptr))->stbp_lastexpr)
#define stab_line(stab)		(((STBP*)(stab->str_ptr))->stbp_line)
#define stab_flags(stab)	(((STBP*)(stab->str_ptr))->stbp_flags)
#define stab_name(stab)		(stab->str_magic->str_ptr)

#define SF_VMAGIC 1		/* call routine to dereference STR val */
#define SF_MULTI 2		/* seen more than once */

struct stio {
    FILE	*ifp;		/* ifp and ofp are normally the same */
    FILE	*ofp;		/* but sockets need separate streams */
#if defined(I_DIRENT) || defined(I_SYSDIR)
    DIR		*dirp;		/* for opendir, readdir, etc */
#endif
    long	lines;		/* $. */
    long	page;		/* $% */
    long	page_len;	/* $= */
    long	lines_left;	/* $- */
    char	*top_name;	/* $^ */
    STAB	*top_stab;	/* $^ */
    char	*fmt_name;	/* $~ */
    STAB	*fmt_stab;	/* $~ */
    short	subprocess;	/* -| or |- */
    char	type;
    char	flags;
};

#define IOF_ARGV 1	/* this fp iterates over ARGV */
#define IOF_START 2	/* check for null ARGV and substitute '-' */
#define IOF_FLUSH 4	/* this fp wants a flush after write op */

struct sub {
    CMD		*cmd;
    char	*filename;
    long	depth;	/* >= 2 indicates recursive call */
    ARRAY	*tosave;
};

#define Nullstab Null(STAB*)

#define STAB_STR(s) (tmpstab = (s), stab_flags(tmpstab) & SF_VMAGIC ? stab_str(stab_val(tmpstab)->str_magic) : stab_val(tmpstab))
#define STAB_GET(s) (tmpstab = (s), str_get(stab_flags(tmpstab) & SF_VMAGIC ? stab_str(tmpstab->str_magic) : stab_val(tmpstab)))
#define STAB_GNUM(s) (tmpstab = (s), str_gnum(stab_flags(tmpstab) & SF_VMAGIC ? stab_str(tmpstab->str_magic) : stab_val(tmpstab)))

EXT STAB *tmpstab;

EXT STAB *stab_index[128];

EXT unsigned short statusvalue;

EXT int delaymagic INIT(0);
#define DM_DELAY 1
#define DM_REUID 2
#define DM_REGID 4

STAB *aadd();
STAB *hadd();
