#ifndef PERL_CALLCONV
#  define PERL_CALLCONV
#endif 

#ifdef PERL_OBJECT
#define VIRTUAL virtual PERL_CALLCONV
#else
#define VIRTUAL PERL_CALLCONV
START_EXTERN_C
#endif

/* NOTE!!! When new virtual functions are added, they must be added at
 * the end of this file to maintain binary compatibility with PERL_OBJECT
 */


#ifndef NEXT30_NO_ATTRIBUTE
#ifndef HASATTRIBUTE       /* disable GNU-cc attribute checking? */
#ifdef  __attribute__      /* Avoid possible redefinition errors */
#undef  __attribute__
#endif
#define __attribute__(attr)
#endif
#endif
VIRTUAL SV*	amagic_call _((SV* left,SV* right,int method,int dir));
VIRTUAL bool	Gv_AMupdate _((HV* stash));
VIRTUAL OP*	append_elem _((I32 optype, OP* head, OP* tail));
VIRTUAL OP*	append_list _((I32 optype, LISTOP* first, LISTOP* last));
VIRTUAL I32	apply _((I32 type, SV** mark, SV** sp));
VIRTUAL void	assertref _((OP* o));
VIRTUAL bool	avhv_exists_ent _((AV *ar, SV* keysv, U32 hash));
VIRTUAL SV**	avhv_fetch_ent _((AV *ar, SV* keysv, I32 lval, U32 hash));
VIRTUAL HE*	avhv_iternext _((AV *ar));
VIRTUAL SV*	avhv_iterval _((AV *ar, HE* entry));
VIRTUAL HV*	avhv_keys _((AV *ar));
VIRTUAL void	av_clear _((AV* ar));
VIRTUAL void	av_extend _((AV* ar, I32 key));
VIRTUAL AV*	av_fake _((I32 size, SV** svp));
VIRTUAL SV**	av_fetch _((AV* ar, I32 key, I32 lval));
VIRTUAL void	av_fill _((AV* ar, I32 fill));
VIRTUAL I32	av_len _((AV* ar));
VIRTUAL AV*	av_make _((I32 size, SV** svp));
VIRTUAL SV*	av_pop _((AV* ar));
VIRTUAL void	av_push _((AV* ar, SV* val));
VIRTUAL void	av_reify _((AV* ar));
VIRTUAL SV*	av_shift _((AV* ar));
VIRTUAL SV**	av_store _((AV* ar, I32 key, SV* val));
VIRTUAL void	av_undef _((AV* ar));
VIRTUAL void	av_unshift _((AV* ar, I32 num));
VIRTUAL OP*	bind_match _((I32 type, OP* left, OP* pat));
VIRTUAL OP*	block_end _((I32 floor, OP* seq));
VIRTUAL I32	block_gimme _((void));
VIRTUAL int	block_start _((int full));
VIRTUAL void	boot_core_UNIVERSAL _((void));
VIRTUAL void	call_list _((I32 oldscope, AV* av_list));
VIRTUAL I32	cando _((I32 bit, I32 effective, Stat_t* statbufp));
VIRTUAL U32	cast_ulong _((double f));
VIRTUAL I32	cast_i32 _((double f));
VIRTUAL IV	cast_iv _((double f));
VIRTUAL UV	cast_uv _((double f));
#if !defined(HAS_TRUNCATE) && !defined(HAS_CHSIZE) && defined(F_FREESP)
VIRTUAL I32	my_chsize _((int fd, Off_t length));
#endif

#ifdef USE_THREADS
VIRTUAL MAGIC *	condpair_magic _((SV *sv));
#endif
VIRTUAL OP*	convert _((I32 optype, I32 flags, OP* o));
VIRTUAL void	croak _((const char* pat,...)) __attribute__((noreturn));
VIRTUAL void	cv_ckproto _((CV* cv, GV* gv, char* p));
VIRTUAL CV*	cv_clone _((CV* proto));
VIRTUAL SV*	cv_const_sv _((CV* cv));
VIRTUAL SV*	op_const_sv _((OP* o, CV* cv));
VIRTUAL void	cv_undef _((CV* cv));
VIRTUAL void	cx_dump _((PERL_CONTEXT* cs));
VIRTUAL SV*	filter_add _((filter_t funcp, SV* datasv));
VIRTUAL void	filter_del _((filter_t funcp));
VIRTUAL I32	filter_read _((int idx, SV* buffer, int maxlen));
VIRTUAL char **	get_op_descs _((void));
VIRTUAL char **	get_op_names _((void));
VIRTUAL char *	get_no_modify _((void));
VIRTUAL U32 *	get_opargs _((void));
VIRTUAL I32	cxinc _((void));
VIRTUAL void	deb _((const char* pat,...));
VIRTUAL void	deb_growlevel _((void));
VIRTUAL void	debprofdump _((void));
VIRTUAL I32	debop _((OP* o));
VIRTUAL I32	debstack _((void));
VIRTUAL I32	debstackptrs _((void));
VIRTUAL char*	delimcpy _((char* to, char* toend, char* from, char* fromend,
		    int delim, I32* retlen));
VIRTUAL void	deprecate _((char* s));
VIRTUAL OP*	die _((const char* pat,...));
VIRTUAL OP*	die_where _((char* message));
VIRTUAL void	dounwind _((I32 cxix));
VIRTUAL bool	do_aexec _((SV* really, SV** mark, SV** sp));
VIRTUAL int	do_binmode _((PerlIO *fp, int iotype, int flag));
VIRTUAL void    do_chop _((SV* asv, SV* sv));
VIRTUAL bool	do_close _((GV* gv, bool not_implicit));
VIRTUAL bool	do_eof _((GV* gv));
VIRTUAL bool	do_exec _((char* cmd));
VIRTUAL void	do_execfree _((void));
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
I32	do_ipcctl _((I32 optype, SV** mark, SV** sp));
I32	do_ipcget _((I32 optype, SV** mark, SV** sp));
#endif
VIRTUAL void	do_join _((SV* sv, SV* del, SV** mark, SV** sp));
VIRTUAL OP*	do_kv _((ARGSproto));
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
I32	do_msgrcv _((SV** mark, SV** sp));
I32	do_msgsnd _((SV** mark, SV** sp));
#endif
VIRTUAL bool	do_open _((GV* gv, char* name, I32 len,
		   int as_raw, int rawmode, int rawperm, PerlIO* supplied_fp));
VIRTUAL void	do_pipe _((SV* sv, GV* rgv, GV* wgv));
VIRTUAL bool	do_print _((SV* sv, PerlIO* fp));
VIRTUAL OP*	do_readline _((void));
VIRTUAL I32	do_chomp _((SV* sv));
VIRTUAL bool	do_seek _((GV* gv, Off_t pos, int whence));
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
I32	do_semop _((SV** mark, SV** sp));
I32	do_shmio _((I32 optype, SV** mark, SV** sp));
#endif
VIRTUAL void	do_sprintf _((SV* sv, I32 len, SV** sarg));
VIRTUAL Off_t	do_sysseek _((GV* gv, Off_t pos, int whence));
VIRTUAL Off_t	do_tell _((GV* gv));
VIRTUAL I32	do_trans _((SV* sv));
VIRTUAL void	do_vecset _((SV* sv));
VIRTUAL void	do_vop _((I32 optype, SV* sv, SV* left, SV* right));
VIRTUAL OP*	dofile _((OP* term));
VIRTUAL I32	dowantarray _((void));
VIRTUAL void	dump_all _((void));
VIRTUAL void	dump_eval _((void));
#ifdef DUMP_FDS  /* See util.c */
VIRTUAL void	dump_fds _((char* s));
#endif
VIRTUAL void	dump_form _((GV* gv));
VIRTUAL void	gv_dump _((GV* gv));
#ifdef MYMALLOC
VIRTUAL void	dump_mstats _((char* s));
#endif
VIRTUAL void	op_dump _((OP* arg));
VIRTUAL void	pmop_dump _((PMOP* pm));
VIRTUAL void	dump_packsubs _((HV* stash));
VIRTUAL void	dump_sub _((GV* gv));
VIRTUAL void	fbm_compile _((SV* sv, U32 flags));
VIRTUAL char*	fbm_instr _((unsigned char* big, unsigned char* bigend, SV* littlesv, U32 flags));
VIRTUAL char*	find_script _((char *scriptname, bool dosearch, char **search_ext, I32 flags));
#ifdef USE_THREADS
VIRTUAL PADOFFSET	find_threadsv _((const char *name));
#endif
VIRTUAL OP*	force_list _((OP* arg));
VIRTUAL OP*	fold_constants _((OP* arg));
VIRTUAL char*	form _((const char* pat, ...));
VIRTUAL void	free_tmps _((void));
VIRTUAL OP*	gen_constant_list _((OP* o));
VIRTUAL void	gp_free _((GV* gv));
VIRTUAL GP*	gp_ref _((GP* gp));
VIRTUAL GV*	gv_AVadd _((GV* gv));
VIRTUAL GV*	gv_HVadd _((GV* gv));
VIRTUAL GV*	gv_IOadd _((GV* gv));
VIRTUAL GV*	gv_autoload4 _((HV* stash, const char* name, STRLEN len, I32 method));
VIRTUAL void	gv_check _((HV* stash));
VIRTUAL void	gv_efullname _((SV* sv, GV* gv));
VIRTUAL void	gv_efullname3 _((SV* sv, GV* gv, const char* prefix));
VIRTUAL GV*	gv_fetchfile _((const char* name));
VIRTUAL GV*	gv_fetchmeth _((HV* stash, const char* name, STRLEN len, I32 level));
VIRTUAL GV*	gv_fetchmethod _((HV* stash, const char* name));
VIRTUAL GV*	gv_fetchmethod_autoload _((HV* stash, const char* name, I32 autoload));
VIRTUAL GV*	gv_fetchpv _((const char* name, I32 add, I32 sv_type));
VIRTUAL void	gv_fullname _((SV* sv, GV* gv));
VIRTUAL void	gv_fullname3 _((SV* sv, GV* gv, const char* prefix));
VIRTUAL void	gv_init _((GV* gv, HV* stash, const char* name, STRLEN len, int multi));
VIRTUAL HV*	gv_stashpv _((const char* name, I32 create));
VIRTUAL HV*	gv_stashpvn _((const char* name, U32 namelen, I32 create));
VIRTUAL HV*	gv_stashsv _((SV* sv, I32 create));
VIRTUAL void	hv_clear _((HV* tb));
VIRTUAL void	hv_delayfree_ent _((HV* hv, HE* entry));
VIRTUAL SV*	hv_delete _((HV* tb, const char* key, U32 klen, I32 flags));
VIRTUAL SV*	hv_delete_ent _((HV* tb, SV* key, I32 flags, U32 hash));
VIRTUAL bool	hv_exists _((HV* tb, const char* key, U32 klen));
VIRTUAL bool	hv_exists_ent _((HV* tb, SV* key, U32 hash));
VIRTUAL SV**	hv_fetch _((HV* tb, const char* key, U32 klen, I32 lval));
VIRTUAL HE*	hv_fetch_ent _((HV* tb, SV* key, I32 lval, U32 hash));
VIRTUAL void	hv_free_ent _((HV* hv, HE* entry));
VIRTUAL I32	hv_iterinit _((HV* tb));
VIRTUAL char*	hv_iterkey _((HE* entry, I32* retlen));
VIRTUAL SV*	hv_iterkeysv _((HE* entry));
VIRTUAL HE*	hv_iternext _((HV* tb));
VIRTUAL SV*	hv_iternextsv _((HV* hv, char** key, I32* retlen));
VIRTUAL SV*	hv_iterval _((HV* tb, HE* entry));
VIRTUAL void	hv_ksplit _((HV* hv, IV newmax));
VIRTUAL void	hv_magic _((HV* hv, GV* gv, int how));
VIRTUAL SV**	hv_store _((HV* tb, const char* key, U32 klen, SV* val, U32 hash));
VIRTUAL HE*	hv_store_ent _((HV* tb, SV* key, SV* val, U32 hash));
VIRTUAL void	hv_undef _((HV* tb));
VIRTUAL I32	ibcmp _((const char* a, const char* b, I32 len));
VIRTUAL I32	ibcmp_locale _((const char* a, const char* b, I32 len));
VIRTUAL I32	ingroup _((I32 testgid, I32 effective));
VIRTUAL void	init_stacks _((ARGSproto));
VIRTUAL U32	intro_my _((void));
VIRTUAL char*	instr _((const char* big, const char* little));
VIRTUAL bool	io_close _((IO* io));
VIRTUAL OP*	invert _((OP* cmd));
VIRTUAL bool	is_uni_alnum _((U32 c));
VIRTUAL bool	is_uni_idfirst _((U32 c));
VIRTUAL bool	is_uni_alpha _((U32 c));
VIRTUAL bool	is_uni_space _((U32 c));
VIRTUAL bool	is_uni_digit _((U32 c));
VIRTUAL bool	is_uni_upper _((U32 c));
VIRTUAL bool	is_uni_lower _((U32 c));
VIRTUAL bool	is_uni_print _((U32 c));
VIRTUAL U32	to_uni_upper _((U32 c));
VIRTUAL U32	to_uni_title _((U32 c));
VIRTUAL U32	to_uni_lower _((U32 c));
VIRTUAL bool	is_uni_alnum_lc _((U32 c));
VIRTUAL bool	is_uni_idfirst_lc _((U32 c));
VIRTUAL bool	is_uni_alpha_lc _((U32 c));
VIRTUAL bool	is_uni_space_lc _((U32 c));
VIRTUAL bool	is_uni_digit_lc _((U32 c));
VIRTUAL bool	is_uni_upper_lc _((U32 c));
VIRTUAL bool	is_uni_lower_lc _((U32 c));
VIRTUAL bool	is_uni_print_lc _((U32 c));
VIRTUAL U32	to_uni_upper_lc _((U32 c));
VIRTUAL U32	to_uni_title_lc _((U32 c));
VIRTUAL U32	to_uni_lower_lc _((U32 c));
VIRTUAL bool	is_utf8_alnum _((U8 *p));
VIRTUAL bool	is_utf8_idfirst _((U8 *p));
VIRTUAL bool	is_utf8_alpha _((U8 *p));
VIRTUAL bool	is_utf8_space _((U8 *p));
VIRTUAL bool	is_utf8_digit _((U8 *p));
VIRTUAL bool	is_utf8_upper _((U8 *p));
VIRTUAL bool	is_utf8_lower _((U8 *p));
VIRTUAL bool	is_utf8_print _((U8 *p));
VIRTUAL bool	is_utf8_mark _((U8 *p));
VIRTUAL OP*	jmaybe _((OP* arg));
VIRTUAL I32	keyword _((char* d, I32 len));
VIRTUAL void	leave_scope _((I32 base));
VIRTUAL void	lex_end _((void));
VIRTUAL void	lex_start _((SV* line));
VIRTUAL OP*	linklist _((OP* o));
VIRTUAL OP*	list _((OP* o));
VIRTUAL OP*	listkids _((OP* o));
VIRTUAL OP*	localize _((OP* arg, I32 lexical));
VIRTUAL I32	looks_like_number _((SV* sv));
VIRTUAL int	magic_clearenv	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_clear_all_env _((SV* sv, MAGIC* mg));
VIRTUAL int	magic_clearpack	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_clearsig	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_existspack _((SV* sv, MAGIC* mg));
VIRTUAL int	magic_freeregexp _((SV* sv, MAGIC* mg));
VIRTUAL int	magic_get	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_getarylen	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_getdefelem _((SV* sv, MAGIC* mg));
VIRTUAL int	magic_getglob	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_getnkeys	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_getpack	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_getpos	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_getsig	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_getsubstr	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_gettaint	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_getuvar	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_getvec	_((SV* sv, MAGIC* mg));
VIRTUAL U32	magic_len	_((SV* sv, MAGIC* mg));
#ifdef USE_THREADS
VIRTUAL int	magic_mutexfree	_((SV* sv, MAGIC* mg));
#endif /* USE_THREADS */
VIRTUAL int	magic_nextpack	_((SV* sv, MAGIC* mg, SV* key));
VIRTUAL U32	magic_regdata_cnt	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_regdatum_get	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_set	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setamagic	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setarylen	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setbm	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setdbline	_((SV* sv, MAGIC* mg));
#ifdef USE_LOCALE_COLLATE
VIRTUAL int	magic_setcollxfrm _((SV* sv, MAGIC* mg));
#endif
VIRTUAL int	magic_setdefelem _((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setenv	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setfm	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setisa	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setglob	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setmglob	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setnkeys	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setpack	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setpos	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setsig	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setsubstr	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_settaint	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setuvar	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_setvec	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_set_all_env _((SV* sv, MAGIC* mg));
VIRTUAL U32	magic_sizepack	_((SV* sv, MAGIC* mg));
VIRTUAL int	magic_wipepack	_((SV* sv, MAGIC* mg));
VIRTUAL void	magicname _((char* sym, char* name, I32 namlen));
int	main _((int argc, char** argv, char** env));
#ifdef MYMALLOC
VIRTUAL MEM_SIZE	malloced_size _((void *p));
#endif
VIRTUAL void	markstack_grow _((void));
#ifdef USE_LOCALE_COLLATE
VIRTUAL char*	mem_collxfrm _((const char* s, STRLEN len, STRLEN* xlen));
#endif
VIRTUAL char*	mess _((const char* pat, va_list* args));
VIRTUAL int	mg_clear _((SV* sv));
VIRTUAL int	mg_copy _((SV* sv, SV* nsv, const char* key, I32 klen));
VIRTUAL MAGIC*	mg_find _((SV* sv, int type));
VIRTUAL int	mg_free _((SV* sv));
VIRTUAL int	mg_get _((SV* sv));
VIRTUAL U32	mg_length _((SV* sv));
VIRTUAL void	mg_magical _((SV* sv));
VIRTUAL int	mg_set _((SV* sv));
VIRTUAL I32	mg_size _((SV* sv));
VIRTUAL OP*	mod _((OP* o, I32 type));
VIRTUAL char*	moreswitches _((char* s));
VIRTUAL OP*	my _((OP* o));
#if !defined(HAS_BCOPY) || !defined(HAS_SAFE_BCOPY)
VIRTUAL char*	my_bcopy _((const char* from, char* to, I32 len));
#endif
#if !defined(HAS_BZERO) && !defined(HAS_MEMSET)
char*	my_bzero _((char* loc, I32 len));
#endif
VIRTUAL void	my_exit _((U32 status)) __attribute__((noreturn));
VIRTUAL void	my_failure_exit _((void)) __attribute__((noreturn));
VIRTUAL I32	my_lstat _((ARGSproto));
#if !defined(HAS_MEMCMP) || !defined(HAS_SANE_MEMCMP)
VIRTUAL I32	my_memcmp _((const char* s1, const char* s2, I32 len));
#endif
#if !defined(HAS_MEMSET)
VIRTUAL void*	my_memset _((char* loc, I32 ch, I32 len));
#endif
#ifndef PERL_OBJECT
VIRTUAL I32	my_pclose _((PerlIO* ptr));
VIRTUAL PerlIO*	my_popen _((char* cmd, char* mode));
#endif
VIRTUAL void	my_setenv _((char* nam, char* val));
VIRTUAL I32	my_stat _((ARGSproto));
#ifdef MYSWAP
VIRTUAL short	my_swap _((short s));
VIRTUAL long	my_htonl _((long l));
VIRTUAL long	my_ntohl _((long l));
#endif
VIRTUAL void	my_unexec _((void));
VIRTUAL OP*	newANONLIST _((OP* o));
VIRTUAL OP*	newANONHASH _((OP* o));
VIRTUAL OP*	newANONSUB _((I32 floor, OP* proto, OP* block));
VIRTUAL OP*	newASSIGNOP _((I32 flags, OP* left, I32 optype, OP* right));
VIRTUAL OP*	newCONDOP _((I32 flags, OP* expr, OP* trueop, OP* falseop));
VIRTUAL void	newCONSTSUB _((HV* stash, char* name, SV* sv));
VIRTUAL void	newFORM _((I32 floor, OP* o, OP* block));
VIRTUAL OP*	newFOROP _((I32 flags, char* label, line_t forline, OP* sclr, OP* expr, OP*block, OP*cont));
VIRTUAL OP*	newLOGOP _((I32 optype, I32 flags, OP* left, OP* right));
VIRTUAL OP*	newLOOPEX _((I32 type, OP* label));
VIRTUAL OP*	newLOOPOP _((I32 flags, I32 debuggable, OP* expr, OP* block));
VIRTUAL OP*	newNULLLIST _((void));
VIRTUAL OP*	newOP _((I32 optype, I32 flags));
VIRTUAL void	newPROG _((OP* o));
VIRTUAL OP*	newRANGE _((I32 flags, OP* left, OP* right));
VIRTUAL OP*	newSLICEOP _((I32 flags, OP* subscript, OP* listop));
VIRTUAL OP*	newSTATEOP _((I32 flags, char* label, OP* o));
VIRTUAL CV*	newSUB _((I32 floor, OP* o, OP* proto, OP* block));
VIRTUAL CV*	newXS _((char* name, void (*subaddr)(CV* cv _CPERLproto), char* filename));
VIRTUAL AV*	newAV _((void));
VIRTUAL OP*	newAVREF _((OP* o));
VIRTUAL OP*	newBINOP _((I32 type, I32 flags, OP* first, OP* last));
VIRTUAL OP*	newCVREF _((I32 flags, OP* o));
VIRTUAL OP*	newGVOP _((I32 type, I32 flags, GV* gv));
VIRTUAL GV*	newGVgen _((char* pack));
VIRTUAL OP*	newGVREF _((I32 type, OP* o));
VIRTUAL OP*	newHVREF _((OP* o));
VIRTUAL HV*	newHV _((void));
VIRTUAL HV*	newHVhv _((HV* hv));
VIRTUAL IO*	newIO _((void));
VIRTUAL OP*	newLISTOP _((I32 type, I32 flags, OP* first, OP* last));
VIRTUAL OP*	newPMOP _((I32 type, I32 flags));
VIRTUAL OP*	newPVOP _((I32 type, I32 flags, char* pv));
VIRTUAL SV*	newRV _((SV* pref));
VIRTUAL SV*	newRV_noinc _((SV *sv));
VIRTUAL SV*	newSV _((STRLEN len));
VIRTUAL OP*	newSVREF _((OP* o));
VIRTUAL OP*	newSVOP _((I32 type, I32 flags, SV* sv));
VIRTUAL SV*	newSViv _((IV i));
VIRTUAL SV*	newSVnv _((double n));
VIRTUAL SV*	newSVpv _((const char* s, STRLEN len));
VIRTUAL SV*	newSVpvn _((const char *s, STRLEN len));
VIRTUAL SV*	newSVpvf _((const char* pat, ...));
VIRTUAL SV*	newSVrv _((SV* rv, const char* classname));
VIRTUAL SV*	newSVsv _((SV* old));
VIRTUAL OP*	newUNOP _((I32 type, I32 flags, OP* first));
VIRTUAL OP*	newWHILEOP _((I32 flags, I32 debuggable, LOOP* loop,
		      I32 whileline, OP* expr, OP* block, OP* cont));
#ifdef USE_THREADS
VIRTUAL struct perl_thread *	new_struct_thread _((struct perl_thread *t));
#endif
VIRTUAL PERL_SI *	new_stackinfo _((I32 stitems, I32 cxitems));
VIRTUAL PerlIO*	nextargv _((GV* gv));
VIRTUAL char*	ninstr _((const char* big, const char* bigend, const char* little, const char* lend));
VIRTUAL OP*	oopsCV _((OP* o));
VIRTUAL void	op_free _((OP* arg));
VIRTUAL void	package _((OP* o));
VIRTUAL PADOFFSET	pad_alloc _((I32 optype, U32 tmptype));
VIRTUAL PADOFFSET	pad_allocmy _((char* name));
VIRTUAL PADOFFSET	pad_findmy _((char* name));
VIRTUAL OP*	oopsAV _((OP* o));
VIRTUAL OP*	oopsHV _((OP* o));
VIRTUAL void	pad_leavemy _((I32 fill));
VIRTUAL SV*	pad_sv _((PADOFFSET po));
VIRTUAL void	pad_free _((PADOFFSET po));
VIRTUAL void	pad_reset _((void));
VIRTUAL void	pad_swipe _((PADOFFSET po));
VIRTUAL void	peep _((OP* o));
#ifndef PERL_OBJECT
PerlInterpreter*	perl_alloc _((void));
#endif
#ifdef PERL_OBJECT
VIRTUAL void    perl_atexit _((void(*fn)(CPerlObj *, void *), void* ptr));
#else
void    perl_atexit _((void(*fn)(void *), void*));
#endif
VIRTUAL I32	perl_call_argv _((const char* sub_name, I32 flags, char** argv));
VIRTUAL I32	perl_call_method _((const char* methname, I32 flags));
VIRTUAL I32	perl_call_pv _((const char* sub_name, I32 flags));
VIRTUAL I32	perl_call_sv _((SV* sv, I32 flags));
#ifdef PERL_OBJECT
VIRTUAL void	perl_construct _((void));
VIRTUAL void	perl_destruct _((void));
#else
void	perl_construct _((PerlInterpreter* sv_interp));
void	perl_destruct _((PerlInterpreter* sv_interp));
#endif
VIRTUAL SV*	perl_eval_pv _((const char* p, I32 croak_on_error));
VIRTUAL I32	perl_eval_sv _((SV* sv, I32 flags));
#ifdef PERL_OBJECT
VIRTUAL void	perl_free _((void));
#else
void	perl_free _((PerlInterpreter* sv_interp));
#endif
VIRTUAL SV*	perl_get_sv _((const char* name, I32 create));
VIRTUAL AV*	perl_get_av _((const char* name, I32 create));
VIRTUAL HV*	perl_get_hv _((const char* name, I32 create));
VIRTUAL CV*	perl_get_cv _((const char* name, I32 create));
VIRTUAL int	perl_init_i18nl10n _((int printwarn));
VIRTUAL int	perl_init_i18nl14n _((int printwarn));
VIRTUAL void	perl_new_collate _((const char* newcoll));
VIRTUAL void	perl_new_ctype _((const char* newctype));
VIRTUAL void	perl_new_numeric _((const char* newcoll));
VIRTUAL void	perl_set_numeric_local _((void));
VIRTUAL void	perl_set_numeric_standard _((void));
#ifdef PERL_OBJECT
VIRTUAL int	perl_parse _((void(*xsinit)(CPerlObj*), int argc, char** argv, char** env));
#else
int	perl_parse _((PerlInterpreter* sv_interp, void(*xsinit)(void), int argc, char** argv, char** env));
#endif
VIRTUAL void	perl_require_pv _((const char* pv));
#define perl_requirepv perl_require_pv
#ifdef PERL_OBJECT
VIRTUAL int	perl_run _((void));
#else
int	perl_run _((PerlInterpreter* sv_interp));
#endif
VIRTUAL void	pidgone _((int pid, int status));
VIRTUAL void	pmflag _((U16* pmfl, int ch));
VIRTUAL OP*	pmruntime _((OP* pm, OP* expr, OP* repl));
VIRTUAL OP*	pmtrans _((OP* o, OP* expr, OP* repl));
VIRTUAL OP*	pop_return _((void));
VIRTUAL void	pop_scope _((void));
VIRTUAL OP*	prepend_elem _((I32 optype, OP* head, OP* tail));
VIRTUAL void	push_return _((OP* o));
VIRTUAL void	push_scope _((void));
VIRTUAL OP*	ref _((OP* o, I32 type));
VIRTUAL OP*	refkids _((OP* o, I32 type));
VIRTUAL void	regdump _((regexp* r));
VIRTUAL I32	pregexec _((regexp* prog, char* stringarg, char* strend, char* strbeg, I32 minend, SV* screamer, U32 nosave));
VIRTUAL void	pregfree _((struct regexp* r));
VIRTUAL regexp*	pregcomp _((char* exp, char* xend, PMOP* pm));
VIRTUAL I32	regexec_flags _((regexp* prog, char* stringarg, char* strend,
			 char* strbeg, I32 minend, SV* screamer,
			 void* data, U32 flags));
VIRTUAL regnode* regnext _((regnode* p));
VIRTUAL void	regprop _((SV* sv, regnode* o));
VIRTUAL void	repeatcpy _((char* to, const char* from, I32 len, I32 count));
VIRTUAL char*	rninstr _((const char* big, const char* bigend, const char* little, const char* lend));
VIRTUAL Sighandler_t rsignal _((int i, Sighandler_t t));
VIRTUAL int	rsignal_restore _((int i, Sigsave_t* t));
VIRTUAL int	rsignal_save _((int i, Sighandler_t t1, Sigsave_t* t2));
VIRTUAL Sighandler_t rsignal_state _((int i));
VIRTUAL void	rxres_free _((void** rsp));
VIRTUAL void	rxres_restore _((void** rsp, REGEXP* prx));
VIRTUAL void	rxres_save _((void** rsp, REGEXP* prx));
#ifndef HAS_RENAME
VIRTUAL I32	same_dirent _((char* a, char* b));
#endif
VIRTUAL char*	savepv _((const char* sv));
VIRTUAL char*	savepvn _((const char* sv, I32 len));
VIRTUAL void	savestack_grow _((void));
VIRTUAL void	save_aelem _((AV* av, I32 idx, SV **sptr));
VIRTUAL I32	save_alloc _((I32 size, I32 pad));
VIRTUAL void	save_aptr _((AV** aptr));
VIRTUAL AV*	save_ary _((GV* gv));
VIRTUAL void	save_clearsv _((SV** svp));
VIRTUAL void	save_delete _((HV* hv, char* key, I32 klen));
#ifndef titan  /* TitanOS cc can't handle this */
#ifdef PERL_OBJECT
typedef void (CPerlObj::*DESTRUCTORFUNC) _((void*));
VIRTUAL void	save_destructor _((DESTRUCTORFUNC f, void* p));
#else
void	save_destructor _((void (*f)(void*), void* p));
#endif
#endif /* titan */
VIRTUAL void	save_freesv _((SV* sv));
VIRTUAL void	save_freeop _((OP* o));
VIRTUAL void	save_freepv _((char* pv));
VIRTUAL void	save_generic_svref _((SV** sptr));
VIRTUAL void	save_gp _((GV* gv, I32 empty));
VIRTUAL HV*	save_hash _((GV* gv));
VIRTUAL void	save_helem _((HV* hv, SV *key, SV **sptr));
VIRTUAL void	save_hints _((void));
VIRTUAL void	save_hptr _((HV** hptr));
VIRTUAL void	save_I16 _((I16* intp));
VIRTUAL void	save_I32 _((I32* intp));
VIRTUAL void	save_int _((int* intp));
VIRTUAL void	save_item _((SV* item));
VIRTUAL void	save_iv _((IV* iv));
VIRTUAL void	save_list _((SV** sarg, I32 maxsarg));
VIRTUAL void	save_long _((long* longp));
VIRTUAL void	save_nogv _((GV* gv));
VIRTUAL void	save_op _((void));
VIRTUAL SV*	save_scalar _((GV* gv));
VIRTUAL void	save_pptr _((char** pptr));
VIRTUAL void	save_re_context _((void));
VIRTUAL void	save_sptr _((SV** sptr));
VIRTUAL SV*	save_svref _((SV** sptr));
VIRTUAL SV**	save_threadsv _((PADOFFSET i));
VIRTUAL OP*	sawparens _((OP* o));
VIRTUAL OP*	scalar _((OP* o));
VIRTUAL OP*	scalarkids _((OP* o));
VIRTUAL OP*	scalarseq _((OP* o));
VIRTUAL OP*	scalarvoid _((OP* o));
VIRTUAL UV	scan_bin _((char* start, I32 len, I32* retlen));
VIRTUAL UV	scan_hex _((char* start, I32 len, I32* retlen));
VIRTUAL char*	scan_num _((char* s));
VIRTUAL UV	scan_oct _((char* start, I32 len, I32* retlen));
VIRTUAL OP*	scope _((OP* o));
VIRTUAL char*	screaminstr _((SV* bigsv, SV* littlesv, I32 start_shift, I32 end_shift, I32 *state, I32 last));
#ifndef VMS
VIRTUAL I32	setenv_getix _((char* nam));
#endif
VIRTUAL void	setdefout _((GV* gv));
VIRTUAL char*	sharepvn _((const char* sv, I32 len, U32 hash));
VIRTUAL HEK*	share_hek _((const char* sv, I32 len, U32 hash));
VIRTUAL Signal_t sighandler _((int sig));
VIRTUAL SV**	stack_grow _((SV** sp, SV**p, int n));
VIRTUAL I32	start_subparse _((I32 is_format, U32 flags));
VIRTUAL void	sub_crush_depth _((CV* cv));
VIRTUAL bool	sv_2bool _((SV* sv));
VIRTUAL CV*	sv_2cv _((SV* sv, HV** st, GV** gvp, I32 lref));
VIRTUAL IO*	sv_2io _((SV* sv));
VIRTUAL IV	sv_2iv _((SV* sv));
VIRTUAL SV*	sv_2mortal _((SV* sv));
VIRTUAL double	sv_2nv _((SV* sv));
VIRTUAL char*	sv_2pv _((SV* sv, STRLEN* lp));
VIRTUAL UV	sv_2uv _((SV* sv));
VIRTUAL IV	sv_iv _((SV* sv));
VIRTUAL UV	sv_uv _((SV* sv));
VIRTUAL double	sv_nv _((SV* sv));
VIRTUAL char *	sv_pvn _((SV *sv, STRLEN *len));
VIRTUAL I32	sv_true _((SV *sv));
VIRTUAL void	sv_add_arena _((char* ptr, U32 size, U32 flags));
VIRTUAL int	sv_backoff _((SV* sv));
VIRTUAL SV*	sv_bless _((SV* sv, HV* stash));
VIRTUAL void	sv_catpvf _((SV* sv, const char* pat, ...));
VIRTUAL void	sv_catpv _((SV* sv, const char* ptr));
VIRTUAL void	sv_catpvn _((SV* sv, const char* ptr, STRLEN len));
VIRTUAL void	sv_catsv _((SV* dsv, SV* ssv));
VIRTUAL void	sv_chop _((SV* sv, char* ptr));
VIRTUAL void	sv_clean_all _((void));
VIRTUAL void	sv_clean_objs _((void));
VIRTUAL void	sv_clear _((SV* sv));
VIRTUAL I32	sv_cmp _((SV* sv1, SV* sv2));
VIRTUAL I32	sv_cmp_locale _((SV* sv1, SV* sv2));
#ifdef USE_LOCALE_COLLATE
VIRTUAL char*	sv_collxfrm _((SV* sv, STRLEN* nxp));
#endif
VIRTUAL OP*	sv_compile_2op _((SV* sv, OP** startp, char* code, AV** avp));
VIRTUAL void	sv_dec _((SV* sv));
VIRTUAL void	sv_dump _((SV* sv));
VIRTUAL bool	sv_derived_from _((SV* sv, const char* name));
VIRTUAL I32	sv_eq _((SV* sv1, SV* sv2));
VIRTUAL void	sv_free _((SV* sv));
VIRTUAL void	sv_free_arenas _((void));
VIRTUAL char*	sv_gets _((SV* sv, PerlIO* fp, I32 append));
VIRTUAL char*	sv_grow _((SV* sv, STRLEN newlen));
VIRTUAL void	sv_inc _((SV* sv));
VIRTUAL void	sv_insert _((SV* bigsv, STRLEN offset, STRLEN len, char* little, STRLEN littlelen));
VIRTUAL int	sv_isa _((SV* sv, const char* name));
VIRTUAL int	sv_isobject _((SV* sv));
VIRTUAL STRLEN	sv_len _((SV* sv));
VIRTUAL STRLEN	sv_len_utf8 _((SV* sv));
VIRTUAL void	sv_magic _((SV* sv, SV* obj, int how, const char* name, I32 namlen));
VIRTUAL SV*	sv_mortalcopy _((SV* oldsv));
VIRTUAL SV*	sv_newmortal _((void));
VIRTUAL SV*	sv_newref _((SV* sv));
VIRTUAL char*	sv_peek _((SV* sv));
VIRTUAL void	sv_pos_u2b _((SV* sv, I32* offsetp, I32* lenp));
VIRTUAL void	sv_pos_b2u _((SV* sv, I32* offsetp));
VIRTUAL char*	sv_pvn_force _((SV* sv, STRLEN* lp));
VIRTUAL char*	sv_reftype _((SV* sv, int ob));
VIRTUAL void	sv_replace _((SV* sv, SV* nsv));
VIRTUAL void	sv_report_used _((void));
VIRTUAL void	sv_reset _((char* s, HV* stash));
VIRTUAL void	sv_setpvf _((SV* sv, const char* pat, ...));
VIRTUAL void	sv_setiv _((SV* sv, IV num));
VIRTUAL void	sv_setpviv _((SV* sv, IV num));
VIRTUAL void	sv_setuv _((SV* sv, UV num));
VIRTUAL void	sv_setnv _((SV* sv, double num));
VIRTUAL SV*	sv_setref_iv _((SV* rv, const char* classname, IV iv));
VIRTUAL SV*	sv_setref_nv _((SV* rv, const char* classname, double nv));
VIRTUAL SV*	sv_setref_pv _((SV* rv, const char* classname, void* pv));
VIRTUAL SV*	sv_setref_pvn _((SV* rv, const char* classname, char* pv, I32 n));
VIRTUAL void	sv_setpv _((SV* sv, const char* ptr));
VIRTUAL void	sv_setpvn _((SV* sv, const char* ptr, STRLEN len));
VIRTUAL void	sv_setsv _((SV* dsv, SV* ssv));
VIRTUAL void	sv_taint _((SV* sv));
VIRTUAL bool	sv_tainted _((SV* sv));
VIRTUAL int	sv_unmagic _((SV* sv, int type));
VIRTUAL void	sv_unref _((SV* sv));
VIRTUAL void	sv_untaint _((SV* sv));
VIRTUAL bool	sv_upgrade _((SV* sv, U32 mt));
VIRTUAL void	sv_usepvn _((SV* sv, char* ptr, STRLEN len));
VIRTUAL void	sv_vcatpvfn _((SV* sv, const char* pat, STRLEN patlen,
		       va_list* args, SV** svargs, I32 svmax,
		       bool *used_locale));
VIRTUAL void	sv_vsetpvfn _((SV* sv, const char* pat, STRLEN patlen,
		       va_list* args, SV** svargs, I32 svmax,
		       bool *used_locale));
VIRTUAL SV*	swash_init _((char* pkg, char* name, SV* listsv, I32 minbits, I32 none));
VIRTUAL UV	swash_fetch _((SV *sv, U8 *ptr));
VIRTUAL void	taint_env _((void));
VIRTUAL void	taint_proper _((const char* f, char* s));
VIRTUAL UV	to_utf8_lower _((U8 *p));
VIRTUAL UV	to_utf8_upper _((U8 *p));
VIRTUAL UV	to_utf8_title _((U8 *p));
#ifdef UNLINK_ALL_VERSIONS
VIRTUAL I32	unlnk _((char* f));
#endif
#ifdef USE_THREADS
VIRTUAL void	unlock_condpair _((void* svv));
#endif
VIRTUAL void	unsharepvn _((const char* sv, I32 len, U32 hash));
VIRTUAL void	unshare_hek _((HEK* hek));
VIRTUAL void	utilize _((int aver, I32 floor, OP* version, OP* id, OP* arg));
VIRTUAL U8*	utf16_to_utf8 _((U16* p, U8 *d, I32 bytelen));
VIRTUAL U8*	utf16_to_utf8_reversed _((U16* p, U8 *d, I32 bytelen));
VIRTUAL I32	utf8_distance _((U8 *a, U8 *b));
VIRTUAL U8*	utf8_hop _((U8 *s, I32 off));
VIRTUAL UV	utf8_to_uv _((U8 *s, I32* retlen));
VIRTUAL U8*	uv_to_utf8 _((U8 *d, UV uv));
VIRTUAL void	vivify_defelem _((SV* sv));
VIRTUAL void	vivify_ref _((SV* sv, U32 to_what));
VIRTUAL I32	wait4pid _((int pid, int* statusp, int flags));
VIRTUAL void	warn _((const char* pat,...));
VIRTUAL void	warner _((U32 err, const char* pat,...));
VIRTUAL void	watch _((char** addr));
VIRTUAL I32	whichsig _((char* sig));
VIRTUAL int	yyerror _((char* s));
#ifdef USE_PURE_BISON
# define PERL_YYLEX_PARAM_DECL YYSTYPE *lvalp, int *lcharp
#else
# define PERL_YYLEX_PARAM_DECL void
#endif
VIRTUAL int	yylex _((PERL_YYLEX_PARAM_DECL));
VIRTUAL int	yyparse _((void));
VIRTUAL int	yywarn _((char* s));

VIRTUAL Malloc_t safesysmalloc _((MEM_SIZE nbytes));
VIRTUAL Malloc_t safesyscalloc _((MEM_SIZE elements, MEM_SIZE size));
VIRTUAL Malloc_t safesysrealloc _((Malloc_t where, MEM_SIZE nbytes));
VIRTUAL Free_t   safesysfree _((Malloc_t where));

#ifdef LEAKTEST
VIRTUAL Malloc_t safexmalloc _((I32 x, MEM_SIZE size));
VIRTUAL Malloc_t safexcalloc _((I32 x, MEM_SIZE elements, MEM_SIZE size));
VIRTUAL Malloc_t safexrealloc _((Malloc_t where, MEM_SIZE size));
VIRTUAL void     safexfree _((Malloc_t where));
#endif

#ifdef PERL_GLOBAL_STRUCT
VIRTUAL struct perl_vars *Perl_GetVars _((void));
#endif

#ifdef PERL_OBJECT
protected:
void hsplit _((HV *hv));
void hfreeentries _((HV *hv));
void more_he _((void));
HE* new_he _((void));
void del_he _((HE *p));
HEK *save_hek _((const char *str, I32 len, U32 hash));
SV *mess_alloc _((void));
void gv_init_sv _((GV *gv, I32 sv_type));
SV *save_scalar_at _((SV **sptr));
IV asIV _((SV* sv));
UV asUV _((SV* sv));
SV *more_sv _((void));
void more_xiv _((void));
void more_xnv _((void));
void more_xpv _((void));
void more_xrv _((void));
XPVIV *new_xiv _((void));
XPVNV *new_xnv _((void));
XPV *new_xpv _((void));
XRV *new_xrv _((void));
void del_xiv _((XPVIV* p));
void del_xnv _((XPVNV* p));
void del_xpv _((XPV* p));
void del_xrv _((XRV* p));
void sv_mortalgrow _((void));
void sv_unglob _((SV* sv));
void sv_check_thinkfirst _((SV *sv));
I32 avhv_index_sv _((SV* sv));

void do_report_used _((SV *sv));
void do_clean_objs _((SV *sv));
void do_clean_named_objs _((SV *sv));
void do_clean_all _((SV *sv));
void not_a_number _((SV *sv));
void* my_safemalloc _((MEM_SIZE size));

typedef void (CPerlObj::*SVFUNC) _((SV*));
void visit _((SVFUNC f));

typedef I32 (CPerlObj::*SVCOMPARE) _((SV*, SV*));
void qsortsv _((SV ** array, size_t num_elts, SVCOMPARE f));
I32 sortcv _((SV *a, SV *b));
void save_magic _((I32 mgs_ix, SV *sv));
int magic_methpack _((SV *sv, MAGIC *mg, char *meth));
int magic_methcall _((SV *sv, MAGIC *mg, char *meth, I32 f, int n, SV *val));
int magic_methcall _((MAGIC *mg, char *meth, I32 flags, int n, SV *val));
OP * doform _((CV *cv, GV *gv, OP *retop));
void doencodes _((SV* sv, char* s, I32 len));
SV* refto _((SV* sv));
U32 seed _((void));
OP *docatch _((OP *o));
OP *dofindlabel _((OP *o, char *label, OP **opstack, OP **oplimit));
void doparseform _((SV *sv));
I32 dopoptoeval _((I32 startingblock));
I32 dopoptolabel _((char *label));
I32 dopoptoloop _((I32 startingblock));
I32 dopoptosub _((I32 startingblock));
I32 dopoptosub_at _((PERL_CONTEXT* cxstk, I32 startingblock));
void save_lines _((AV *array, SV *sv));
OP *doeval _((int gimme, OP** startop));
I32 sv_ncmp _((SV *a, SV *b));
I32 sv_i_ncmp _((SV *a, SV *b));
I32 amagic_ncmp _((SV *a, SV *b));
I32 amagic_i_ncmp _((SV *a, SV *b));
I32 amagic_cmp _((SV *str1, SV *str2));
I32 amagic_cmp_locale _((SV *str1, SV *str2));

SV *mul128 _((SV *sv, U8 m));
SV *is_an_int _((char *s, STRLEN l));
int div128 _((SV *pnum, bool *done));

int runops_standard _((void));
int runops_debug _((void));

void check_uni _((void));
void  force_next _((I32 type));
char *force_version _((char *start));
char *force_word _((char *start, int token, int check_keyword, int allow_pack, int allow_tick));
SV *tokeq _((SV *sv));
char *scan_const _((char *start));
char *scan_formline _((char *s));
char *scan_heredoc _((char *s));
char *scan_ident _((char *s, char *send, char *dest, STRLEN destlen, I32 ck_uni));
char *scan_inputsymbol _((char *start));
char *scan_pat _((char *start, I32 type));
char *scan_str _((char *start));
char *scan_subst _((char *start));
char *scan_trans _((char *start));
char *scan_word _((char *s, char *dest, STRLEN destlen, int allow_package, STRLEN *slp));
char *skipspace _((char *s));
void checkcomma _((char *s, char *name, char *what));
void force_ident _((char *s, int kind));
void incline _((char *s));
int intuit_method _((char *s, GV *gv));
int intuit_more _((char *s));
I32 lop _((I32 f, expectation x, char *s));
void missingterm _((char *s));
void no_op _((char *what, char *s));
void set_csh _((void));
I32 sublex_done _((void));
I32 sublex_push _((void));
I32 sublex_start _((void));
#ifdef CRIPPLED_CC
int uni _((I32 f, char *s));
#endif
char * filter_gets _((SV *sv, PerlIO *fp, STRLEN append));
SV *new_constant _((char *s, STRLEN len, char *key, SV *sv, SV *pv, char *type));
int ao _((int toketype));
void depcom _((void));
#ifdef WIN32
I32 win32_textfilter _((int idx, SV *sv, int maxlen));
#endif
char* incl_perldb _((void));
SV *isa_lookup _((HV *stash, const char *name, int len, int level));
CV *get_db_sub _((SV **svp, CV *cv));
I32 list_assignment _((OP *o));
void bad_type _((I32 n, char *t, char *name, OP *kid));
OP *modkids _((OP *o, I32 type));
OP *no_fh_allowed _((OP *o));
OP *scalarboolean _((OP *o));
OP *too_few_arguments _((OP *o, char* name));
OP *too_many_arguments _((OP *o, char* name));
void null _((OP* o));
PADOFFSET pad_findlex _((char* name, PADOFFSET newoff, U32 seq, CV* startcv, I32 cx_ix, I32 saweval, U32 flags));
OP *newDEFSVOP _((void));
char* gv_ename _((GV *gv));
CV *cv_clone2 _((CV *proto, CV *outside));

void find_beginning _((void));
void forbid_setid _((char *));
void incpush _((char *, int));
void init_interp _((void));
void init_ids _((void));
void init_debugger _((void));
void init_lexer _((void));
void init_main_stash _((void));
#ifdef USE_THREADS
struct perl_thread * init_main_thread _((void));
#endif /* USE_THREADS */
void init_perllib _((void));
void init_postdump_symbols _((int, char **, char **));
void init_predump_symbols _((void));
void my_exit_jump _((void)) __attribute__((noreturn));
void nuke_stacks _((void));
void open_script _((char *, bool, SV *, int *fd));
void usage _((char *));
void validate_suid _((char *, char*, int));
int emulate_eaccess _((const char* path, int mode));

regnode *reg _((I32, I32 *));
regnode *reganode _((U8, U32));
regnode *regatom _((I32 *));
regnode *regbranch _((I32 *, I32));
void regc _((U8, char *));
void reguni _((UV, char *, I32*));
regnode *regclass _((void));
regnode *regclassutf8 _((void));
I32 regcurly _((char *));
regnode *reg_node _((U8));
regnode *regpiece _((I32 *));
void reginsert _((U8, regnode *));
void regoptail _((regnode *, regnode *));
void regset _((char *, I32));
void regtail _((regnode *, regnode *));
char* regwhite _((char *, char *));
char* nextchar _((void));
regnode *dumpuntil _((regnode *start, regnode *node, regnode *last, SV* sv, I32 l));
void scan_commit _((scan_data_t *data));
I32 study_chunk _((regnode **scanp, I32 *deltap, regnode *last, scan_data_t *data, U32 flags));
I32 add_data _((I32 n, char *s));
void	re_croak2 _((const char* pat1,const char* pat2,...)) __attribute__((noreturn));
char* regpposixcc _((I32 value));
void clear_re _((void *r));
I32 regmatch _((regnode *prog));
I32 regrepeat _((regnode *p, I32 max));
I32 regrepeat_hard _((regnode *p, I32 max, I32 *lp));
I32 regtry _((regexp *prog, char *startpos));
bool reginclass _((char *p, I32 c));
bool reginclassutf8 _((regnode *f, U8* p));
CHECKPOINT regcppush _((I32 parenfloor));
char * regcppop _((void));
char * regcp_set_to _((I32 ss));
void cache_re _((regexp *prog));
void restore_pos _((void *arg));
U8 * reghop _((U8 *pos, I32 off));
U8 * reghopmaybe _((U8 *pos, I32 off));
void dump _((char *pat,...));
#ifdef WIN32
int do_aspawn _((void *vreally, void **vmark, void **vsp));
#endif

#ifdef DEBUGGING
void del_sv _((SV *p));
#endif
void debprof _((OP *o));

void *bset_obj_store _((void *obj, I32 ix));
OP *new_logop _((I32 type, I32 flags, OP **firstp, OP **otherp));
void simplify_sort _((OP *o));
bool is_handle_constructor _((OP *o, I32 argnum));

I32 do_trans_CC_simple _((SV *sv));
I32 do_trans_CC_count _((SV *sv));
I32 do_trans_CC_complex _((SV *sv));
I32 do_trans_UU_simple _((SV *sv));
I32 do_trans_UU_count _((SV *sv));
I32 do_trans_UU_complex _((SV *sv));
I32 do_trans_UC_simple _((SV *sv));
I32 do_trans_CU_simple _((SV *sv));
I32 do_trans_UC_trivial _((SV *sv));
I32 do_trans_CU_trivial _((SV *sv));

#undef PERL_CKDEF
#undef PERL_PPDEF
#define PERL_CKDEF(s) OP* s _((OP *o));
#define PERL_PPDEF(s) OP* s _((ARGSproto));
public:

#include "pp_proto.h"

void unwind_handler_stack _((void *p));
void restore_magic _((void *p));
void restore_rsfp _((void *f));
void restore_expect _((void *e));
void restore_lex_expect _((void *e));
void yydestruct _((void *ptr));
VIRTUAL int fprintf _((PerlIO *pf, const char *pat, ...));
VIRTUAL SV**	get_specialsv_list _((void));

#ifdef WIN32
VIRTUAL int&	ErrorNo _((void));
#endif	/* WIN32 */
#else	/* !PERL_OBJECT */
END_EXTERN_C
#endif	/* PERL_OBJECT */

#ifdef INDIRECT_BGET_MACROS
VIRTUAL void byterun _((struct bytestream bs));
#else
VIRTUAL void byterun _((PerlIO *fp));
#endif /* INDIRECT_BGET_MACROS */

VIRTUAL void	sv_catpvf_mg _((SV *sv, const char* pat, ...));
VIRTUAL void	sv_catpv_mg _((SV *sv, const char *ptr));
VIRTUAL void	sv_catpvn_mg _((SV *sv, const char *ptr, STRLEN len));
VIRTUAL void	sv_catsv_mg _((SV *dstr, SV *sstr));
VIRTUAL void	sv_setpvf_mg _((SV *sv, const char* pat, ...));
VIRTUAL void	sv_setiv_mg _((SV *sv, IV i));
VIRTUAL void	sv_setpviv_mg _((SV *sv, IV iv));
VIRTUAL void	sv_setuv_mg _((SV *sv, UV u));
VIRTUAL void	sv_setnv_mg _((SV *sv, double num));
VIRTUAL void	sv_setpv_mg _((SV *sv, const char *ptr));
VIRTUAL void	sv_setpvn_mg _((SV *sv, const char *ptr, STRLEN len));
VIRTUAL void	sv_setsv_mg _((SV *dstr, SV *sstr));
VIRTUAL void	sv_usepvn_mg _((SV *sv, char *ptr, STRLEN len));

VIRTUAL MGVTBL*	get_vtbl _((int vtbl_id));

/* New virtual functions must be added here to maintain binary
 * compatablity with PERL_OBJECT
 */

VIRTUAL char* pv_display _((SV *sv, char *pv, STRLEN cur, STRLEN len, STRLEN pvlim));
VIRTUAL void dump_indent _((I32 level, PerlIO *file, const char* pat, ...));

VIRTUAL void do_gv_dump _((I32 level, PerlIO *file, char *name, GV *sv));
VIRTUAL void do_gvgv_dump _((I32 level, PerlIO *file, char *name, GV *sv));
VIRTUAL void do_hv_dump _((I32 level, PerlIO *file, char *name, HV *sv));
VIRTUAL void do_magic_dump _((I32 level, PerlIO *file, MAGIC *mg, I32 nest, I32 maxnest, bool dumpops, STRLEN pvlim));
VIRTUAL void do_op_dump _((I32 level, PerlIO *file, OP *o));
VIRTUAL void do_pmop_dump _((I32 level, PerlIO *file, PMOP *pm));
VIRTUAL void do_sv_dump _((I32 level, PerlIO *file, SV *sv, I32 nest, I32 maxnest, bool dumpops, STRLEN pvlim));
VIRTUAL void magic_dump _((MAGIC *mg));
VIRTUAL void reginitcolors _((void));
VIRTUAL char* sv_2pv_nolen _((SV* sv));
VIRTUAL char* sv_pv _((SV *sv));
