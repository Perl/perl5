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
VIRTUAL SV*	amagic_call (SV* left,SV* right,int method,int dir);
VIRTUAL bool	Gv_AMupdate (HV* stash);
VIRTUAL OP*	append_elem (I32 optype, OP* head, OP* tail);
VIRTUAL OP*	append_list (I32 optype, LISTOP* first, LISTOP* last);
VIRTUAL I32	apply (I32 type, SV** mark, SV** sp);
VIRTUAL void	assertref (OP* o);
VIRTUAL bool	avhv_exists_ent (AV *ar, SV* keysv, U32 hash);
VIRTUAL SV**	avhv_fetch_ent (AV *ar, SV* keysv, I32 lval, U32 hash);
VIRTUAL HE*	avhv_iternext (AV *ar);
VIRTUAL SV*	avhv_iterval (AV *ar, HE* entry);
VIRTUAL HV*	avhv_keys (AV *ar);
VIRTUAL void	av_clear (AV* ar);
VIRTUAL void	av_extend (AV* ar, I32 key);
VIRTUAL AV*	av_fake (I32 size, SV** svp);
VIRTUAL SV**	av_fetch (AV* ar, I32 key, I32 lval);
VIRTUAL void	av_fill (AV* ar, I32 fill);
VIRTUAL I32	av_len (AV* ar);
VIRTUAL AV*	av_make (I32 size, SV** svp);
VIRTUAL SV*	av_pop (AV* ar);
VIRTUAL void	av_push (AV* ar, SV* val);
VIRTUAL void	av_reify (AV* ar);
VIRTUAL SV*	av_shift (AV* ar);
VIRTUAL SV**	av_store (AV* ar, I32 key, SV* val);
VIRTUAL void	av_undef (AV* ar);
VIRTUAL void	av_unshift (AV* ar, I32 num);
VIRTUAL OP*	bind_match (I32 type, OP* left, OP* pat);
VIRTUAL OP*	block_end (I32 floor, OP* seq);
VIRTUAL I32	block_gimme (void);
VIRTUAL int	block_start (int full);
VIRTUAL void	boot_core_UNIVERSAL (void);
VIRTUAL void	call_list (I32 oldscope, AV* av_list);
VIRTUAL I32	cando (I32 bit, I32 effective, Stat_t* statbufp);
VIRTUAL U32	cast_ulong (double f);
VIRTUAL I32	cast_i32 (double f);
VIRTUAL IV	cast_iv (double f);
VIRTUAL UV	cast_uv (double f);
#if !defined(HAS_TRUNCATE) && !defined(HAS_CHSIZE) && defined(F_FREESP)
VIRTUAL I32	my_chsize (int fd, Off_t length);
#endif

#ifdef USE_THREADS
VIRTUAL MAGIC *	condpair_magic (SV *sv);
#endif
VIRTUAL OP*	convert (I32 optype, I32 flags, OP* o);
VIRTUAL void	croak (const char* pat,...) __attribute__((noreturn));
VIRTUAL void	cv_ckproto (CV* cv, GV* gv, char* p);
VIRTUAL CV*	cv_clone (CV* proto);
VIRTUAL SV*	cv_const_sv (CV* cv);
VIRTUAL SV*	op_const_sv (OP* o, CV* cv);
VIRTUAL void	cv_undef (CV* cv);
VIRTUAL void	cx_dump (PERL_CONTEXT* cs);
VIRTUAL SV*	filter_add (filter_t funcp, SV* datasv);
VIRTUAL void	filter_del (filter_t funcp);
VIRTUAL I32	filter_read (int idx, SV* buffer, int maxlen);
VIRTUAL char **	get_op_descs (void);
VIRTUAL char **	get_op_names (void);
VIRTUAL char *	get_no_modify (void);
VIRTUAL U32 *	get_opargs (void);
VIRTUAL I32	cxinc (void);
VIRTUAL void	deb (const char* pat,...);
VIRTUAL void	deb_growlevel (void);
VIRTUAL void	debprofdump (void);
VIRTUAL I32	debop (OP* o);
VIRTUAL I32	debstack (void);
VIRTUAL I32	debstackptrs (void);
VIRTUAL char*	delimcpy (char* to, char* toend, char* from, char* fromend,
		    int delim, I32* retlen);
VIRTUAL void	deprecate (char* s);
VIRTUAL OP*	die (const char* pat,...);
VIRTUAL OP*	die_where (char* message, STRLEN msglen);
VIRTUAL void	dounwind (I32 cxix);
VIRTUAL bool	do_aexec (SV* really, SV** mark, SV** sp);
VIRTUAL int	do_binmode (PerlIO *fp, int iotype, int flag);
VIRTUAL void    do_chop (SV* asv, SV* sv);
VIRTUAL bool	do_close (GV* gv, bool not_implicit);
VIRTUAL bool	do_eof (GV* gv);
VIRTUAL bool	do_exec (char* cmd);
#ifndef WIN32
VIRTUAL bool	do_exec3 (char* cmd, int fd, int flag);
#endif
VIRTUAL void	do_execfree (void);
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
VIRTUAL I32	do_ipcctl (I32 optype, SV** mark, SV** sp);
VIRTUAL I32	do_ipcget (I32 optype, SV** mark, SV** sp);
#endif
VIRTUAL void	do_join (SV* sv, SV* del, SV** mark, SV** sp);
VIRTUAL OP*	do_kv (ARGSproto);
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
VIRTUAL I32	do_msgrcv (SV** mark, SV** sp);
VIRTUAL I32	do_msgsnd (SV** mark, SV** sp);
#endif
VIRTUAL bool	do_open (GV* gv, char* name, I32 len,
		   int as_raw, int rawmode, int rawperm, PerlIO* supplied_fp);
VIRTUAL void	do_pipe (SV* sv, GV* rgv, GV* wgv);
VIRTUAL bool	do_print (SV* sv, PerlIO* fp);
VIRTUAL OP*	do_readline (void);
VIRTUAL I32	do_chomp (SV* sv);
VIRTUAL bool	do_seek (GV* gv, Off_t pos, int whence);
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
VIRTUAL I32	do_semop (SV** mark, SV** sp);
VIRTUAL I32	do_shmio (I32 optype, SV** mark, SV** sp);
#endif
VIRTUAL void	do_sprintf (SV* sv, I32 len, SV** sarg);
VIRTUAL Off_t	do_sysseek (GV* gv, Off_t pos, int whence);
VIRTUAL Off_t	do_tell (GV* gv);
VIRTUAL I32	do_trans (SV* sv);
VIRTUAL void	do_vecset (SV* sv);
VIRTUAL void	do_vop (I32 optype, SV* sv, SV* left, SV* right);
VIRTUAL OP*	dofile (OP* term);
VIRTUAL I32	dowantarray (void);
VIRTUAL void	dump_all (void);
VIRTUAL void	dump_eval (void);
#ifdef DUMP_FDS  /* See util.c */
VIRTUAL void	dump_fds (char* s);
#endif
VIRTUAL void	dump_form (GV* gv);
VIRTUAL void	gv_dump (GV* gv);
#ifdef MYMALLOC
VIRTUAL void	dump_mstats (char* s);
#endif
VIRTUAL void	op_dump (OP* arg);
VIRTUAL void	pmop_dump (PMOP* pm);
VIRTUAL void	dump_packsubs (HV* stash);
VIRTUAL void	dump_sub (GV* gv);
VIRTUAL void	fbm_compile (SV* sv, U32 flags);
VIRTUAL char*	fbm_instr (unsigned char* big, unsigned char* bigend, SV* littlesv, U32 flags);
VIRTUAL char*	find_script (char *scriptname, bool dosearch, char **search_ext, I32 flags);
#ifdef USE_THREADS
VIRTUAL PADOFFSET	find_threadsv (const char *name);
#endif
VIRTUAL OP*	force_list (OP* arg);
VIRTUAL OP*	fold_constants (OP* arg);
VIRTUAL char*	form (const char* pat, ...);
VIRTUAL void	free_tmps (void);
VIRTUAL OP*	gen_constant_list (OP* o);
#ifndef HAS_GETENV_LEN
VIRTUAL char*	getenv_len (char* key, unsigned long *len);
#endif
VIRTUAL void	gp_free (GV* gv);
VIRTUAL GP*	gp_ref (GP* gp);
VIRTUAL GV*	gv_AVadd (GV* gv);
VIRTUAL GV*	gv_HVadd (GV* gv);
VIRTUAL GV*	gv_IOadd (GV* gv);
VIRTUAL GV*	gv_autoload4 (HV* stash, const char* name, STRLEN len, I32 method);
VIRTUAL void	gv_check (HV* stash);
VIRTUAL void	gv_efullname (SV* sv, GV* gv);
VIRTUAL void	gv_efullname3 (SV* sv, GV* gv, const char* prefix);
VIRTUAL GV*	gv_fetchfile (const char* name);
VIRTUAL GV*	gv_fetchmeth (HV* stash, const char* name, STRLEN len, I32 level);
VIRTUAL GV*	gv_fetchmethod (HV* stash, const char* name);
VIRTUAL GV*	gv_fetchmethod_autoload (HV* stash, const char* name, I32 autoload);
VIRTUAL GV*	gv_fetchpv (const char* name, I32 add, I32 sv_type);
VIRTUAL void	gv_fullname (SV* sv, GV* gv);
VIRTUAL void	gv_fullname3 (SV* sv, GV* gv, const char* prefix);
VIRTUAL void	gv_init (GV* gv, HV* stash, const char* name, STRLEN len, int multi);
VIRTUAL HV*	gv_stashpv (const char* name, I32 create);
VIRTUAL HV*	gv_stashpvn (const char* name, U32 namelen, I32 create);
VIRTUAL HV*	gv_stashsv (SV* sv, I32 create);
VIRTUAL void	hv_clear (HV* tb);
VIRTUAL void	hv_delayfree_ent (HV* hv, HE* entry);
VIRTUAL SV*	hv_delete (HV* tb, const char* key, U32 klen, I32 flags);
VIRTUAL SV*	hv_delete_ent (HV* tb, SV* key, I32 flags, U32 hash);
VIRTUAL bool	hv_exists (HV* tb, const char* key, U32 klen);
VIRTUAL bool	hv_exists_ent (HV* tb, SV* key, U32 hash);
VIRTUAL SV**	hv_fetch (HV* tb, const char* key, U32 klen, I32 lval);
VIRTUAL HE*	hv_fetch_ent (HV* tb, SV* key, I32 lval, U32 hash);
VIRTUAL void	hv_free_ent (HV* hv, HE* entry);
VIRTUAL I32	hv_iterinit (HV* tb);
VIRTUAL char*	hv_iterkey (HE* entry, I32* retlen);
VIRTUAL SV*	hv_iterkeysv (HE* entry);
VIRTUAL HE*	hv_iternext (HV* tb);
VIRTUAL SV*	hv_iternextsv (HV* hv, char** key, I32* retlen);
VIRTUAL SV*	hv_iterval (HV* tb, HE* entry);
VIRTUAL void	hv_ksplit (HV* hv, IV newmax);
VIRTUAL void	hv_magic (HV* hv, GV* gv, int how);
VIRTUAL SV**	hv_store (HV* tb, const char* key, U32 klen, SV* val, U32 hash);
VIRTUAL HE*	hv_store_ent (HV* tb, SV* key, SV* val, U32 hash);
VIRTUAL void	hv_undef (HV* tb);
VIRTUAL I32	ibcmp (const char* a, const char* b, I32 len);
VIRTUAL I32	ibcmp_locale (const char* a, const char* b, I32 len);
VIRTUAL I32	ingroup (I32 testgid, I32 effective);
VIRTUAL void	init_stacks (ARGSproto);
VIRTUAL U32	intro_my (void);
VIRTUAL char*	instr (const char* big, const char* little);
VIRTUAL bool	io_close (IO* io);
VIRTUAL OP*	invert (OP* cmd);
VIRTUAL bool	is_uni_alnum (U32 c);
VIRTUAL bool	is_uni_idfirst (U32 c);
VIRTUAL bool	is_uni_alpha (U32 c);
VIRTUAL bool	is_uni_space (U32 c);
VIRTUAL bool	is_uni_digit (U32 c);
VIRTUAL bool	is_uni_upper (U32 c);
VIRTUAL bool	is_uni_lower (U32 c);
VIRTUAL bool	is_uni_print (U32 c);
VIRTUAL U32	to_uni_upper (U32 c);
VIRTUAL U32	to_uni_title (U32 c);
VIRTUAL U32	to_uni_lower (U32 c);
VIRTUAL bool	is_uni_alnum_lc (U32 c);
VIRTUAL bool	is_uni_idfirst_lc (U32 c);
VIRTUAL bool	is_uni_alpha_lc (U32 c);
VIRTUAL bool	is_uni_space_lc (U32 c);
VIRTUAL bool	is_uni_digit_lc (U32 c);
VIRTUAL bool	is_uni_upper_lc (U32 c);
VIRTUAL bool	is_uni_lower_lc (U32 c);
VIRTUAL bool	is_uni_print_lc (U32 c);
VIRTUAL U32	to_uni_upper_lc (U32 c);
VIRTUAL U32	to_uni_title_lc (U32 c);
VIRTUAL U32	to_uni_lower_lc (U32 c);
VIRTUAL bool	is_utf8_alnum (U8 *p);
VIRTUAL bool	is_utf8_idfirst (U8 *p);
VIRTUAL bool	is_utf8_alpha (U8 *p);
VIRTUAL bool	is_utf8_space (U8 *p);
VIRTUAL bool	is_utf8_digit (U8 *p);
VIRTUAL bool	is_utf8_upper (U8 *p);
VIRTUAL bool	is_utf8_lower (U8 *p);
VIRTUAL bool	is_utf8_print (U8 *p);
VIRTUAL bool	is_utf8_mark (U8 *p);
VIRTUAL OP*	jmaybe (OP* arg);
VIRTUAL I32	keyword (char* d, I32 len);
VIRTUAL void	leave_scope (I32 base);
VIRTUAL void	lex_end (void);
VIRTUAL void	lex_start (SV* line);
VIRTUAL OP*	linklist (OP* o);
VIRTUAL OP*	list (OP* o);
VIRTUAL OP*	listkids (OP* o);
VIRTUAL OP*	localize (OP* arg, I32 lexical);
VIRTUAL I32	looks_like_number (SV* sv);
VIRTUAL int	magic_clearenv	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_clear_all_env (SV* sv, MAGIC* mg);
VIRTUAL int	magic_clearpack	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_clearsig	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_existspack (SV* sv, MAGIC* mg);
VIRTUAL int	magic_freeregexp (SV* sv, MAGIC* mg);
VIRTUAL int	magic_get	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_getarylen	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_getdefelem (SV* sv, MAGIC* mg);
VIRTUAL int	magic_getglob	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_getnkeys	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_getpack	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_getpos	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_getsig	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_getsubstr	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_gettaint	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_getuvar	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_getvec	(SV* sv, MAGIC* mg);
VIRTUAL U32	magic_len	(SV* sv, MAGIC* mg);
#ifdef USE_THREADS
VIRTUAL int	magic_mutexfree	(SV* sv, MAGIC* mg);
#endif /* USE_THREADS */
VIRTUAL int	magic_nextpack	(SV* sv, MAGIC* mg, SV* key);
VIRTUAL U32	magic_regdata_cnt	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_regdatum_get	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_set	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_setamagic	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_setarylen	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_setbm	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_setdbline	(SV* sv, MAGIC* mg);
#ifdef USE_LOCALE_COLLATE
VIRTUAL int	magic_setcollxfrm (SV* sv, MAGIC* mg);
#endif
VIRTUAL int	magic_setdefelem (SV* sv, MAGIC* mg);
VIRTUAL int	magic_setenv	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_setfm	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_setisa	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_setglob	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_setmglob	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_setnkeys	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_setpack	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_setpos	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_setsig	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_setsubstr	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_settaint	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_setuvar	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_setvec	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_set_all_env (SV* sv, MAGIC* mg);
VIRTUAL U32	magic_sizepack	(SV* sv, MAGIC* mg);
VIRTUAL int	magic_wipepack	(SV* sv, MAGIC* mg);
VIRTUAL void	magicname (char* sym, char* name, I32 namlen);
int	main (int argc, char** argv, char** env);
#ifdef MYMALLOC
VIRTUAL MEM_SIZE	malloced_size (void *p);
#endif
VIRTUAL void	markstack_grow (void);
#ifdef USE_LOCALE_COLLATE
VIRTUAL char*	mem_collxfrm (const char* s, STRLEN len, STRLEN* xlen);
#endif
VIRTUAL SV*	mess (const char* pat, va_list* args);
VIRTUAL int	mg_clear (SV* sv);
VIRTUAL int	mg_copy (SV* sv, SV* nsv, const char* key, I32 klen);
VIRTUAL MAGIC*	mg_find (SV* sv, int type);
VIRTUAL int	mg_free (SV* sv);
VIRTUAL int	mg_get (SV* sv);
VIRTUAL U32	mg_length (SV* sv);
VIRTUAL void	mg_magical (SV* sv);
VIRTUAL int	mg_set (SV* sv);
VIRTUAL I32	mg_size (SV* sv);
VIRTUAL OP*	mod (OP* o, I32 type);
VIRTUAL char*	moreswitches (char* s);
VIRTUAL OP*	my (OP* o);
#if !defined(HAS_BCOPY) || !defined(HAS_SAFE_BCOPY)
VIRTUAL char*	my_bcopy (const char* from, char* to, I32 len);
#endif
#if !defined(HAS_BZERO) && !defined(HAS_MEMSET)
VIRTUAL char*	my_bzero (char* loc, I32 len);
#endif
VIRTUAL void	my_exit (U32 status) __attribute__((noreturn));
VIRTUAL void	my_failure_exit (void) __attribute__((noreturn));
VIRTUAL I32	my_fflush_all (void);
VIRTUAL I32	my_lstat (ARGSproto);
#if !defined(HAS_MEMCMP) || !defined(HAS_SANE_MEMCMP)
VIRTUAL I32	my_memcmp (const char* s1, const char* s2, I32 len);
#endif
#if !defined(HAS_MEMSET)
VIRTUAL void*	my_memset (char* loc, I32 ch, I32 len);
#endif
#ifndef PERL_OBJECT
VIRTUAL I32	my_pclose (PerlIO* ptr);
VIRTUAL PerlIO*	my_popen (char* cmd, char* mode);
#endif
VIRTUAL void	my_setenv (char* nam, char* val);
VIRTUAL I32	my_stat (ARGSproto);
#ifdef MYSWAP
VIRTUAL short	my_swap (short s);
VIRTUAL long	my_htonl (long l);
VIRTUAL long	my_ntohl (long l);
#endif
VIRTUAL void	my_unexec (void);
VIRTUAL OP*	newANONLIST (OP* o);
VIRTUAL OP*	newANONHASH (OP* o);
VIRTUAL OP*	newANONSUB (I32 floor, OP* proto, OP* block);
VIRTUAL OP*	newASSIGNOP (I32 flags, OP* left, I32 optype, OP* right);
VIRTUAL OP*	newCONDOP (I32 flags, OP* expr, OP* trueop, OP* falseop);
VIRTUAL void	newCONSTSUB (HV* stash, char* name, SV* sv);
VIRTUAL void	newFORM (I32 floor, OP* o, OP* block);
VIRTUAL OP*	newFOROP (I32 flags, char* label, line_t forline, OP* sclr, OP* expr, OP*block, OP*cont);
VIRTUAL OP*	newLOGOP (I32 optype, I32 flags, OP* left, OP* right);
VIRTUAL OP*	newLOOPEX (I32 type, OP* label);
VIRTUAL OP*	newLOOPOP (I32 flags, I32 debuggable, OP* expr, OP* block);
VIRTUAL OP*	newNULLLIST (void);
VIRTUAL OP*	newOP (I32 optype, I32 flags);
VIRTUAL void	newPROG (OP* o);
VIRTUAL OP*	newRANGE (I32 flags, OP* left, OP* right);
VIRTUAL OP*	newSLICEOP (I32 flags, OP* subscript, OP* listop);
VIRTUAL OP*	newSTATEOP (I32 flags, char* label, OP* o);
VIRTUAL CV*	newSUB (I32 floor, OP* o, OP* proto, OP* block);
VIRTUAL CV*	newXS (char* name, void (*subaddr)(CV* cv _CPERLproto), char* filename);
VIRTUAL AV*	newAV (void);
VIRTUAL OP*	newAVREF (OP* o);
VIRTUAL OP*	newBINOP (I32 type, I32 flags, OP* first, OP* last);
VIRTUAL OP*	newCVREF (I32 flags, OP* o);
VIRTUAL OP*	newGVOP (I32 type, I32 flags, GV* gv);
VIRTUAL GV*	newGVgen (char* pack);
VIRTUAL OP*	newGVREF (I32 type, OP* o);
VIRTUAL OP*	newHVREF (OP* o);
VIRTUAL HV*	newHV (void);
VIRTUAL HV*	newHVhv (HV* hv);
VIRTUAL IO*	newIO (void);
VIRTUAL OP*	newLISTOP (I32 type, I32 flags, OP* first, OP* last);
VIRTUAL OP*	newPMOP (I32 type, I32 flags);
VIRTUAL OP*	newPVOP (I32 type, I32 flags, char* pv);
VIRTUAL SV*	newRV (SV* pref);
VIRTUAL SV*	newRV_noinc (SV *sv);
VIRTUAL SV*	newSV (STRLEN len);
VIRTUAL OP*	newSVREF (OP* o);
VIRTUAL OP*	newSVOP (I32 type, I32 flags, SV* sv);
VIRTUAL SV*	newSViv (IV i);
VIRTUAL SV*	newSVnv (double n);
VIRTUAL SV*	newSVpv (const char* s, STRLEN len);
VIRTUAL SV*	newSVpvn (const char *s, STRLEN len);
VIRTUAL SV*	newSVpvf (const char* pat, ...);
VIRTUAL SV*	newSVrv (SV* rv, const char* classname);
VIRTUAL SV*	newSVsv (SV* old);
VIRTUAL OP*	newUNOP (I32 type, I32 flags, OP* first);
VIRTUAL OP*	newWHILEOP (I32 flags, I32 debuggable, LOOP* loop,
		      I32 whileline, OP* expr, OP* block, OP* cont);
#ifdef USE_THREADS
VIRTUAL struct perl_thread *	new_struct_thread (struct perl_thread *t);
#endif
VIRTUAL PERL_SI *	new_stackinfo (I32 stitems, I32 cxitems);
VIRTUAL PerlIO*	nextargv (GV* gv);
VIRTUAL char*	ninstr (const char* big, const char* bigend, const char* little, const char* lend);
VIRTUAL OP*	oopsCV (OP* o);
VIRTUAL void	op_free (OP* arg);
VIRTUAL void	package (OP* o);
VIRTUAL PADOFFSET	pad_alloc (I32 optype, U32 tmptype);
VIRTUAL PADOFFSET	pad_allocmy (char* name);
VIRTUAL PADOFFSET	pad_findmy (char* name);
VIRTUAL OP*	oopsAV (OP* o);
VIRTUAL OP*	oopsHV (OP* o);
VIRTUAL void	pad_leavemy (I32 fill);
VIRTUAL SV*	pad_sv (PADOFFSET po);
VIRTUAL void	pad_free (PADOFFSET po);
VIRTUAL void	pad_reset (void);
VIRTUAL void	pad_swipe (PADOFFSET po);
VIRTUAL void	peep (OP* o);
#ifndef PERL_OBJECT
PerlInterpreter*	perl_alloc (void);
#endif
#ifdef PERL_OBJECT
VIRTUAL void    perl_atexit (void(*fn)(CPerlObj *, void *), void* ptr);
#else
void    perl_atexit (void(*fn)(void *), void*);
#endif
VIRTUAL I32	perl_call_argv (const char* sub_name, I32 flags, char** argv);
VIRTUAL I32	perl_call_method (const char* methname, I32 flags);
VIRTUAL I32	perl_call_pv (const char* sub_name, I32 flags);
VIRTUAL I32	perl_call_sv (SV* sv, I32 flags);
#ifdef PERL_OBJECT
VIRTUAL void	perl_construct (void);
VIRTUAL void	perl_destruct (void);
#else
void	perl_construct (PerlInterpreter* sv_interp);
void	perl_destruct (PerlInterpreter* sv_interp);
#endif
VIRTUAL SV*	perl_eval_pv (const char* p, I32 croak_on_error);
VIRTUAL I32	perl_eval_sv (SV* sv, I32 flags);
#ifdef PERL_OBJECT
VIRTUAL void	perl_free (void);
#else
void	perl_free (PerlInterpreter* sv_interp);
#endif
VIRTUAL SV*	perl_get_sv (const char* name, I32 create);
VIRTUAL AV*	perl_get_av (const char* name, I32 create);
VIRTUAL HV*	perl_get_hv (const char* name, I32 create);
VIRTUAL CV*	perl_get_cv (const char* name, I32 create);
VIRTUAL int	perl_init_i18nl10n (int printwarn);
VIRTUAL int	perl_init_i18nl14n (int printwarn);
VIRTUAL void	perl_new_collate (const char* newcoll);
VIRTUAL void	perl_new_ctype (const char* newctype);
VIRTUAL void	perl_new_numeric (const char* newcoll);
VIRTUAL void	perl_set_numeric_local (void);
VIRTUAL void	perl_set_numeric_standard (void);
#ifdef PERL_OBJECT
VIRTUAL int	perl_parse (void(*xsinit)(CPerlObj*), int argc, char** argv, char** env);
#else
int	perl_parse (PerlInterpreter* sv_interp, void(*xsinit)(void), int argc, char** argv, char** env);
#endif
VIRTUAL void	perl_require_pv (const char* pv);
#define perl_requirepv perl_require_pv
#ifdef PERL_OBJECT
VIRTUAL int	perl_run (void);
#else
int	perl_run (PerlInterpreter* sv_interp);
#endif
VIRTUAL void	pidgone (int pid, int status);
VIRTUAL void	pmflag (U16* pmfl, int ch);
VIRTUAL OP*	pmruntime (OP* pm, OP* expr, OP* repl);
VIRTUAL OP*	pmtrans (OP* o, OP* expr, OP* repl);
VIRTUAL OP*	pop_return (void);
VIRTUAL void	pop_scope (void);
VIRTUAL OP*	prepend_elem (I32 optype, OP* head, OP* tail);
VIRTUAL void	push_return (OP* o);
VIRTUAL void	push_scope (void);
VIRTUAL OP*	ref (OP* o, I32 type);
VIRTUAL OP*	refkids (OP* o, I32 type);
VIRTUAL void	regdump (regexp* r);
VIRTUAL I32	pregexec (regexp* prog, char* stringarg, char* strend, char* strbeg, I32 minend, SV* screamer, U32 nosave);
VIRTUAL void	pregfree (struct regexp* r);
VIRTUAL regexp*	pregcomp (char* exp, char* xend, PMOP* pm);
VIRTUAL I32	regexec_flags (regexp* prog, char* stringarg, char* strend,
			 char* strbeg, I32 minend, SV* screamer,
			 void* data, U32 flags);
VIRTUAL regnode* regnext (regnode* p);
VIRTUAL void	regprop (SV* sv, regnode* o);
VIRTUAL void	repeatcpy (char* to, const char* from, I32 len, I32 count);
VIRTUAL char*	rninstr (const char* big, const char* bigend, const char* little, const char* lend);
VIRTUAL Sighandler_t rsignal (int i, Sighandler_t t);
VIRTUAL int	rsignal_restore (int i, Sigsave_t* t);
VIRTUAL int	rsignal_save (int i, Sighandler_t t1, Sigsave_t* t2);
VIRTUAL Sighandler_t rsignal_state (int i);
VIRTUAL void	rxres_free (void** rsp);
VIRTUAL void	rxres_restore (void** rsp, REGEXP* prx);
VIRTUAL void	rxres_save (void** rsp, REGEXP* prx);
#ifndef HAS_RENAME
VIRTUAL I32	same_dirent (char* a, char* b);
#endif
VIRTUAL char*	savepv (const char* sv);
VIRTUAL char*	savepvn (const char* sv, I32 len);
VIRTUAL void	savestack_grow (void);
VIRTUAL void	save_aelem (AV* av, I32 idx, SV **sptr);
VIRTUAL I32	save_alloc (I32 size, I32 pad);
VIRTUAL void	save_aptr (AV** aptr);
VIRTUAL AV*	save_ary (GV* gv);
VIRTUAL void	save_clearsv (SV** svp);
VIRTUAL void	save_delete (HV* hv, char* key, I32 klen);
#ifndef titan  /* TitanOS cc can't handle this */
#ifdef PERL_OBJECT
typedef void (CPerlObj::*DESTRUCTORFUNC) (void*);
VIRTUAL void	save_destructor (DESTRUCTORFUNC f, void* p);
#else
void	save_destructor (void (*f)(void*), void* p);
#endif
#endif /* titan */
VIRTUAL void	save_freesv (SV* sv);
VIRTUAL void	save_freeop (OP* o);
VIRTUAL void	save_freepv (char* pv);
VIRTUAL void	save_generic_svref (SV** sptr);
VIRTUAL void	save_gp (GV* gv, I32 empty);
VIRTUAL HV*	save_hash (GV* gv);
VIRTUAL void	save_helem (HV* hv, SV *key, SV **sptr);
VIRTUAL void	save_hints (void);
VIRTUAL void	save_hptr (HV** hptr);
VIRTUAL void	save_I16 (I16* intp);
VIRTUAL void	save_I32 (I32* intp);
VIRTUAL void	save_int (int* intp);
VIRTUAL void	save_item (SV* item);
VIRTUAL void	save_iv (IV* iv);
VIRTUAL void	save_list (SV** sarg, I32 maxsarg);
VIRTUAL void	save_long (long* longp);
VIRTUAL void	save_nogv (GV* gv);
VIRTUAL void	save_op (void);
VIRTUAL SV*	save_scalar (GV* gv);
VIRTUAL void	save_pptr (char** pptr);
VIRTUAL void	save_re_context (void);
VIRTUAL void	save_sptr (SV** sptr);
VIRTUAL SV*	save_svref (SV** sptr);
VIRTUAL SV**	save_threadsv (PADOFFSET i);
VIRTUAL OP*	sawparens (OP* o);
VIRTUAL OP*	scalar (OP* o);
VIRTUAL OP*	scalarkids (OP* o);
VIRTUAL OP*	scalarseq (OP* o);
VIRTUAL OP*	scalarvoid (OP* o);
VIRTUAL UV	scan_bin (char* start, I32 len, I32* retlen);
VIRTUAL UV	scan_hex (char* start, I32 len, I32* retlen);
VIRTUAL char*	scan_num (char* s);
VIRTUAL UV	scan_oct (char* start, I32 len, I32* retlen);
VIRTUAL OP*	scope (OP* o);
VIRTUAL char*	screaminstr (SV* bigsv, SV* littlesv, I32 start_shift, I32 end_shift, I32 *state, I32 last);
#ifndef VMS
VIRTUAL I32	setenv_getix (char* nam);
#endif
VIRTUAL void	setdefout (GV* gv);
VIRTUAL char*	sharepvn (const char* sv, I32 len, U32 hash);
VIRTUAL HEK*	share_hek (const char* sv, I32 len, U32 hash);
VIRTUAL Signal_t sighandler (int sig);
VIRTUAL SV**	stack_grow (SV** sp, SV**p, int n);
VIRTUAL I32	start_subparse (I32 is_format, U32 flags);
VIRTUAL void	sub_crush_depth (CV* cv);
VIRTUAL bool	sv_2bool (SV* sv);
VIRTUAL CV*	sv_2cv (SV* sv, HV** st, GV** gvp, I32 lref);
VIRTUAL IO*	sv_2io (SV* sv);
VIRTUAL IV	sv_2iv (SV* sv);
VIRTUAL SV*	sv_2mortal (SV* sv);
VIRTUAL double	sv_2nv (SV* sv);
VIRTUAL char*	sv_2pv (SV* sv, STRLEN* lp);
VIRTUAL UV	sv_2uv (SV* sv);
VIRTUAL IV	sv_iv (SV* sv);
VIRTUAL UV	sv_uv (SV* sv);
VIRTUAL double	sv_nv (SV* sv);
VIRTUAL char *	sv_pvn (SV *sv, STRLEN *len);
VIRTUAL I32	sv_true (SV *sv);
VIRTUAL void	sv_add_arena (char* ptr, U32 size, U32 flags);
VIRTUAL int	sv_backoff (SV* sv);
VIRTUAL SV*	sv_bless (SV* sv, HV* stash);
VIRTUAL void	sv_catpvf (SV* sv, const char* pat, ...);
VIRTUAL void	sv_catpv (SV* sv, const char* ptr);
VIRTUAL void	sv_catpvn (SV* sv, const char* ptr, STRLEN len);
VIRTUAL void	sv_catsv (SV* dsv, SV* ssv);
VIRTUAL void	sv_chop (SV* sv, char* ptr);
VIRTUAL void	sv_clean_all (void);
VIRTUAL void	sv_clean_objs (void);
VIRTUAL void	sv_clear (SV* sv);
VIRTUAL I32	sv_cmp (SV* sv1, SV* sv2);
VIRTUAL I32	sv_cmp_locale (SV* sv1, SV* sv2);
#ifdef USE_LOCALE_COLLATE
VIRTUAL char*	sv_collxfrm (SV* sv, STRLEN* nxp);
#endif
VIRTUAL OP*	sv_compile_2op (SV* sv, OP** startp, char* code, AV** avp);
VIRTUAL void	sv_dec (SV* sv);
VIRTUAL void	sv_dump (SV* sv);
VIRTUAL bool	sv_derived_from (SV* sv, const char* name);
VIRTUAL I32	sv_eq (SV* sv1, SV* sv2);
VIRTUAL void	sv_free (SV* sv);
VIRTUAL void	sv_free_arenas (void);
VIRTUAL char*	sv_gets (SV* sv, PerlIO* fp, I32 append);
VIRTUAL char*	sv_grow (SV* sv, STRLEN newlen);
VIRTUAL void	sv_inc (SV* sv);
VIRTUAL void	sv_insert (SV* bigsv, STRLEN offset, STRLEN len, char* little, STRLEN littlelen);
VIRTUAL int	sv_isa (SV* sv, const char* name);
VIRTUAL int	sv_isobject (SV* sv);
VIRTUAL STRLEN	sv_len (SV* sv);
VIRTUAL STRLEN	sv_len_utf8 (SV* sv);
VIRTUAL void	sv_magic (SV* sv, SV* obj, int how, const char* name, I32 namlen);
VIRTUAL SV*	sv_mortalcopy (SV* oldsv);
VIRTUAL SV*	sv_newmortal (void);
VIRTUAL SV*	sv_newref (SV* sv);
VIRTUAL char*	sv_peek (SV* sv);
VIRTUAL void	sv_pos_u2b (SV* sv, I32* offsetp, I32* lenp);
VIRTUAL void	sv_pos_b2u (SV* sv, I32* offsetp);
VIRTUAL char*	sv_pvn_force (SV* sv, STRLEN* lp);
VIRTUAL char*	sv_reftype (SV* sv, int ob);
VIRTUAL void	sv_replace (SV* sv, SV* nsv);
VIRTUAL void	sv_report_used (void);
VIRTUAL void	sv_reset (char* s, HV* stash);
VIRTUAL void	sv_setpvf (SV* sv, const char* pat, ...);
VIRTUAL void	sv_setiv (SV* sv, IV num);
VIRTUAL void	sv_setpviv (SV* sv, IV num);
VIRTUAL void	sv_setuv (SV* sv, UV num);
VIRTUAL void	sv_setnv (SV* sv, double num);
VIRTUAL SV*	sv_setref_iv (SV* rv, const char* classname, IV iv);
VIRTUAL SV*	sv_setref_nv (SV* rv, const char* classname, double nv);
VIRTUAL SV*	sv_setref_pv (SV* rv, const char* classname, void* pv);
VIRTUAL SV*	sv_setref_pvn (SV* rv, const char* classname, char* pv, STRLEN n);
VIRTUAL void	sv_setpv (SV* sv, const char* ptr);
VIRTUAL void	sv_setpvn (SV* sv, const char* ptr, STRLEN len);
VIRTUAL void	sv_setsv (SV* dsv, SV* ssv);
VIRTUAL void	sv_taint (SV* sv);
VIRTUAL bool	sv_tainted (SV* sv);
VIRTUAL int	sv_unmagic (SV* sv, int type);
VIRTUAL void	sv_unref (SV* sv);
VIRTUAL void	sv_untaint (SV* sv);
VIRTUAL bool	sv_upgrade (SV* sv, U32 mt);
VIRTUAL void	sv_usepvn (SV* sv, char* ptr, STRLEN len);
VIRTUAL void	sv_vcatpvfn (SV* sv, const char* pat, STRLEN patlen,
		       va_list* args, SV** svargs, I32 svmax,
		       bool *used_locale);
VIRTUAL void	sv_vsetpvfn (SV* sv, const char* pat, STRLEN patlen,
		       va_list* args, SV** svargs, I32 svmax,
		       bool *used_locale);
VIRTUAL SV*	swash_init (char* pkg, char* name, SV* listsv, I32 minbits, I32 none);
VIRTUAL UV	swash_fetch (SV *sv, U8 *ptr);
VIRTUAL void	taint_env (void);
VIRTUAL void	taint_proper (const char* f, char* s);
VIRTUAL UV	to_utf8_lower (U8 *p);
VIRTUAL UV	to_utf8_upper (U8 *p);
VIRTUAL UV	to_utf8_title (U8 *p);
#ifdef UNLINK_ALL_VERSIONS
VIRTUAL I32	unlnk (char* f);
#endif
#ifdef USE_THREADS
VIRTUAL void	unlock_condpair (void* svv);
#endif
VIRTUAL void	unsharepvn (const char* sv, I32 len, U32 hash);
VIRTUAL void	unshare_hek (HEK* hek);
VIRTUAL void	utilize (int aver, I32 floor, OP* version, OP* id, OP* arg);
VIRTUAL U8*	utf16_to_utf8 (U16* p, U8 *d, I32 bytelen);
VIRTUAL U8*	utf16_to_utf8_reversed (U16* p, U8 *d, I32 bytelen);
VIRTUAL I32	utf8_distance (U8 *a, U8 *b);
VIRTUAL U8*	utf8_hop (U8 *s, I32 off);
VIRTUAL UV	utf8_to_uv (U8 *s, I32* retlen);
VIRTUAL U8*	uv_to_utf8 (U8 *d, UV uv);
VIRTUAL void	vivify_defelem (SV* sv);
VIRTUAL void	vivify_ref (SV* sv, U32 to_what);
VIRTUAL I32	wait4pid (int pid, int* statusp, int flags);
VIRTUAL void	warn (const char* pat,...);
VIRTUAL void	warner (U32 err, const char* pat,...);
VIRTUAL void	watch (char** addr);
VIRTUAL I32	whichsig (char* sig);
VIRTUAL int	yyerror (char* s);
#ifdef USE_PURE_BISON
# define PERL_YYLEX_PARAM_DECL YYSTYPE *lvalp, int *lcharp
#else
# define PERL_YYLEX_PARAM_DECL void
#endif
VIRTUAL int	yylex (PERL_YYLEX_PARAM_DECL);
VIRTUAL int	yyparse (void);
VIRTUAL int	yywarn (char* s);

VIRTUAL Malloc_t safesysmalloc (MEM_SIZE nbytes);
VIRTUAL Malloc_t safesyscalloc (MEM_SIZE elements, MEM_SIZE size);
VIRTUAL Malloc_t safesysrealloc (Malloc_t where, MEM_SIZE nbytes);
VIRTUAL Free_t   safesysfree (Malloc_t where);

#ifdef LEAKTEST
VIRTUAL Malloc_t safexmalloc (I32 x, MEM_SIZE size);
VIRTUAL Malloc_t safexcalloc (I32 x, MEM_SIZE elements, MEM_SIZE size);
VIRTUAL Malloc_t safexrealloc (Malloc_t where, MEM_SIZE size);
VIRTUAL void     safexfree (Malloc_t where);
#endif

#ifdef PERL_GLOBAL_STRUCT
VIRTUAL struct perl_vars *Perl_GetVars (void);
#endif

#ifdef PERL_OBJECT
protected:
void hsplit (HV *hv);
void hfreeentries (HV *hv);
void more_he (void);
HE* new_he (void);
void del_he (HE *p);
HEK *save_hek (const char *str, I32 len, U32 hash);
SV *mess_alloc (void);
void gv_init_sv (GV *gv, I32 sv_type);
SV *save_scalar_at (SV **sptr);
IV asIV (SV* sv);
UV asUV (SV* sv);
SV *more_sv (void);
void more_xiv (void);
void more_xnv (void);
void more_xpv (void);
void more_xrv (void);
XPVIV *new_xiv (void);
XPVNV *new_xnv (void);
XPV *new_xpv (void);
XRV *new_xrv (void);
void del_xiv (XPVIV* p);
void del_xnv (XPVNV* p);
void del_xpv (XPV* p);
void del_xrv (XRV* p);
void sv_unglob (SV* sv);
I32 avhv_index_sv (SV* sv);

void do_report_used (SV *sv);
void do_clean_objs (SV *sv);
void do_clean_named_objs (SV *sv);
void do_clean_all (SV *sv);
void not_a_number (SV *sv);
void* my_safemalloc (MEM_SIZE size);

typedef void (CPerlObj::*SVFUNC) (SV*);
void visit (SVFUNC f);

typedef I32 (CPerlObj::*SVCOMPARE) (SV*, SV*);
void qsortsv (SV ** array, size_t num_elts, SVCOMPARE f);
I32 sortcv (SV *a, SV *b);
void save_magic (I32 mgs_ix, SV *sv);
int magic_methpack (SV *sv, MAGIC *mg, char *meth);
int magic_methcall (SV *sv, MAGIC *mg, char *meth, I32 f, int n, SV *val);
int magic_methcall (MAGIC *mg, char *meth, I32 flags, int n, SV *val);
OP * doform (CV *cv, GV *gv, OP *retop);
void doencodes (SV* sv, char* s, I32 len);
SV* refto (SV* sv);
U32 seed (void);
OP *docatch (OP *o);
void *docatch_body (va_list args);
void *perl_parse_body (va_list args);
void *perl_run_body (va_list args);
void *perl_call_body (va_list args);
void perl_call_xbody (OP *myop, int is_eval);
void *call_list_body (va_list args);
OP *dofindlabel (OP *o, char *label, OP **opstack, OP **oplimit);
void doparseform (SV *sv);
I32 dopoptoeval (I32 startingblock);
I32 dopoptolabel (char *label);
I32 dopoptoloop (I32 startingblock);
I32 dopoptosub (I32 startingblock);
I32 dopoptosub_at (PERL_CONTEXT* cxstk, I32 startingblock);
void free_closures (void);
void save_lines (AV *array, SV *sv);
OP *doeval (int gimme, OP** startop);
PerlIO *doopen_pmc (const char *name, const char *mode);
I32 sv_ncmp (SV *a, SV *b);
I32 sv_i_ncmp (SV *a, SV *b);
I32 amagic_ncmp (SV *a, SV *b);
I32 amagic_i_ncmp (SV *a, SV *b);
I32 amagic_cmp (SV *str1, SV *str2);
I32 amagic_cmp_locale (SV *str1, SV *str2);

SV *mul128 (SV *sv, U8 m);
SV *is_an_int (char *s, STRLEN l);
int div128 (SV *pnum, bool *done);
void check_uni (void);
void  force_next (I32 type);
char *force_version (char *start);
char *force_word (char *start, int token, int check_keyword, int allow_pack, int allow_tick);
SV *tokeq (SV *sv);
char *scan_const (char *start);
char *scan_formline (char *s);
char *scan_heredoc (char *s);
char *scan_ident (char *s, char *send, char *dest, STRLEN destlen, I32 ck_uni);
char *scan_inputsymbol (char *start);
char *scan_pat (char *start, I32 type);
char *scan_str (char *start);
char *scan_subst (char *start);
char *scan_trans (char *start);
char *scan_word (char *s, char *dest, STRLEN destlen, int allow_package, STRLEN *slp);
char *skipspace (char *s);
void checkcomma (char *s, char *name, char *what);
void force_ident (char *s, int kind);
void incline (char *s);
int intuit_method (char *s, GV *gv);
int intuit_more (char *s);
I32 lop (I32 f, expectation x, char *s);
void missingterm (char *s);
void no_op (char *what, char *s);
void set_csh (void);
I32 sublex_done (void);
I32 sublex_push (void);
I32 sublex_start (void);
#ifdef CRIPPLED_CC
int uni (I32 f, char *s);
#endif
char * filter_gets (SV *sv, PerlIO *fp, STRLEN append);
SV *new_constant (char *s, STRLEN len, char *key, SV *sv, SV *pv, char *type);
int ao (int toketype);
void depcom (void);
#ifdef WIN32
I32 win32_textfilter (int idx, SV *sv, int maxlen);
#endif
char* incl_perldb (void);
SV *isa_lookup (HV *stash, const char *name, int len, int level);
CV *get_db_sub (SV **svp, CV *cv);
I32 list_assignment (OP *o);
void bad_type (I32 n, char *t, char *name, OP *kid);
OP *modkids (OP *o, I32 type);
void no_bareword_allowed (OP *o);
OP *no_fh_allowed (OP *o);
OP *scalarboolean (OP *o);
OP *too_few_arguments (OP *o, char* name);
OP *too_many_arguments (OP *o, char* name);
void null (OP* o);
PADOFFSET pad_findlex (char* name, PADOFFSET newoff, U32 seq, CV* startcv, I32 cx_ix, I32 saweval, U32 flags);
OP *newDEFSVOP (void);
char* gv_ename (GV *gv);
CV *cv_clone2 (CV *proto, CV *outside);

void find_beginning (void);
void forbid_setid (char *);
void incpush (char *, int);
void init_interp (void);
void init_ids (void);
void init_debugger (void);
void init_lexer (void);
void init_main_stash (void);
#ifdef USE_THREADS
struct perl_thread * init_main_thread (void);
#endif /* USE_THREADS */
void init_perllib (void);
void init_postdump_symbols (int, char **, char **);
void init_predump_symbols (void);
void my_exit_jump (void) __attribute__((noreturn));
void nuke_stacks (void);
void open_script (char *, bool, SV *, int *fd);
void usage (char *);
void validate_suid (char *, char*, int);
int emulate_eaccess (const char* path, int mode);

regnode *reg (I32, I32 *);
regnode *reganode (U8, U32);
regnode *regatom (I32 *);
regnode *regbranch (I32 *, I32);
void regc (U8, char *);
void reguni (UV, char *, I32*);
regnode *regclass (void);
regnode *regclassutf8 (void);
I32 regcurly (char *);
regnode *reg_node (U8);
regnode *regpiece (I32 *);
void reginsert (U8, regnode *);
void regoptail (regnode *, regnode *);
void regset (char *, I32);
void regtail (regnode *, regnode *);
char* regwhite (char *, char *);
char* nextchar (void);
regnode *dumpuntil (regnode *start, regnode *node, regnode *last, SV* sv, I32 l);
void scan_commit (scan_data_t *data);
I32 study_chunk (regnode **scanp, I32 *deltap, regnode *last, scan_data_t *data, U32 flags);
I32 add_data (I32 n, char *s);
void	re_croak2 (const char* pat1,const char* pat2,...) __attribute__((noreturn));
char* regpposixcc (I32 value);
void clear_re (void *r);
I32 regmatch (regnode *prog);
I32 regrepeat (regnode *p, I32 max);
I32 regrepeat_hard (regnode *p, I32 max, I32 *lp);
I32 regtry (regexp *prog, char *startpos);
bool reginclass (char *p, I32 c);
bool reginclassutf8 (regnode *f, U8* p);
CHECKPOINT regcppush (I32 parenfloor);
char * regcppop (void);
char * regcp_set_to (I32 ss);
void cache_re (regexp *prog);
void restore_pos (void *arg);
U8 * reghop (U8 *pos, I32 off);
U8 * reghopmaybe (U8 *pos, I32 off);
void dump (char *pat,...);
#ifdef WIN32
int do_aspawn (void *vreally, void **vmark, void **vsp);
#endif

#ifdef DEBUGGING
void del_sv (SV *p);
#endif
void debprof (OP *o);

OP *new_logop (I32 type, I32 flags, OP **firstp, OP **otherp);
void simplify_sort (OP *o);
bool is_handle_constructor (OP *o, I32 argnum);
void sv_add_backref (SV *tsv, SV *sv);
void sv_del_backref (SV *sv);

I32 do_trans_CC_simple (SV *sv);
I32 do_trans_CC_count (SV *sv);
I32 do_trans_CC_complex (SV *sv);
I32 do_trans_UU_simple (SV *sv);
I32 do_trans_UU_count (SV *sv);
I32 do_trans_UU_complex (SV *sv);
I32 do_trans_UC_simple (SV *sv);
I32 do_trans_CU_simple (SV *sv);
I32 do_trans_UC_trivial (SV *sv);
I32 do_trans_CU_trivial (SV *sv);

#undef PERL_CKDEF
#undef PERL_PPDEF
#define PERL_CKDEF(s) OP* s (OP *o);
#define PERL_PPDEF(s) OP* s (ARGSproto);
public:

#include "pp_proto.h"

void unwind_handler_stack (void *p);
void restore_magic (void *p);
void restore_rsfp (void *f);
void restore_expect (void *e);
void restore_lex_expect (void *e);
VIRTUAL void yydestruct (void *ptr);
VIRTUAL int fprintf (PerlIO *pf, const char *pat, ...);
VIRTUAL int runops_standard (void);
VIRTUAL int runops_debug (void);

#ifdef WIN32
VIRTUAL int&	ErrorNo (void);
#endif	/* WIN32 */
#else	/* !PERL_OBJECT */
END_EXTERN_C
#endif	/* PERL_OBJECT */

VIRTUAL void	sv_catpvf_mg (SV *sv, const char* pat, ...);
VIRTUAL void	sv_catpv_mg (SV *sv, const char *ptr);
VIRTUAL void	sv_catpvn_mg (SV *sv, const char *ptr, STRLEN len);
VIRTUAL void	sv_catsv_mg (SV *dstr, SV *sstr);
VIRTUAL void	sv_setpvf_mg (SV *sv, const char* pat, ...);
VIRTUAL void	sv_setiv_mg (SV *sv, IV i);
VIRTUAL void	sv_setpviv_mg (SV *sv, IV iv);
VIRTUAL void	sv_setuv_mg (SV *sv, UV u);
VIRTUAL void	sv_setnv_mg (SV *sv, double num);
VIRTUAL void	sv_setpv_mg (SV *sv, const char *ptr);
VIRTUAL void	sv_setpvn_mg (SV *sv, const char *ptr, STRLEN len);
VIRTUAL void	sv_setsv_mg (SV *dstr, SV *sstr);
VIRTUAL void	sv_usepvn_mg (SV *sv, char *ptr, STRLEN len);

VIRTUAL MGVTBL*	get_vtbl (int vtbl_id);

/* New virtual functions must be added here to maintain binary
 * compatablity with PERL_OBJECT
 */

VIRTUAL char* pv_display (SV *sv, char *pv, STRLEN cur, STRLEN len, STRLEN pvlim);
VIRTUAL void dump_indent (I32 level, PerlIO *file, const char* pat, ...);

VIRTUAL void do_gv_dump (I32 level, PerlIO *file, char *name, GV *sv);
VIRTUAL void do_gvgv_dump (I32 level, PerlIO *file, char *name, GV *sv);
VIRTUAL void do_hv_dump (I32 level, PerlIO *file, char *name, HV *sv);
VIRTUAL void do_magic_dump (I32 level, PerlIO *file, MAGIC *mg, I32 nest, I32 maxnest, bool dumpops, STRLEN pvlim);
VIRTUAL void do_op_dump (I32 level, PerlIO *file, OP *o);
VIRTUAL void do_pmop_dump (I32 level, PerlIO *file, PMOP *pm);
VIRTUAL void do_sv_dump (I32 level, PerlIO *file, SV *sv, I32 nest, I32 maxnest, bool dumpops, STRLEN pvlim);
VIRTUAL void magic_dump (MAGIC *mg);
VIRTUAL void* default_protect (int *excpt, protect_body_t body, ...);
VIRTUAL void reginitcolors (void);
VIRTUAL char* sv_2pv_nolen (SV* sv);
VIRTUAL char* sv_pv (SV *sv);
VIRTUAL void sv_force_normal (SV *sv);
VIRTUAL void tmps_grow (I32 n);
VIRTUAL void *bset_obj_store (void *obj, I32 ix);

VIRTUAL SV* sv_rvweaken (SV *sv);
VIRTUAL int magic_killbackrefs (SV *sv, MAGIC *mg);
