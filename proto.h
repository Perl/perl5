#if defined(WIN32)
int&	Perl_ErrorNo(pTHX);
#endif
#if defined(PERL_GLOBAL_STRUCT)
struct perl_vars *	Perl_GetVars(pTHX);
#endif
bool	Perl_Gv_AMupdate(pTHX_ HV* stash);
SV*	Perl_amagic_call(pTHX_ SV* left, SV* right, int method, int dir);
OP*	Perl_append_elem(pTHX_ I32 optype, OP* head, OP* tail);
OP*	Perl_append_list(pTHX_ I32 optype, LISTOP* first, LISTOP* last);
I32	Perl_apply(pTHX_ I32 type, SV** mark, SV** sp);
void	Perl_assertref(pTHX_ OP* o);
void	Perl_av_clear(pTHX_ AV* ar);
void	Perl_av_extend(pTHX_ AV* ar, I32 key);
AV*	Perl_av_fake(pTHX_ I32 size, SV** svp);
SV**	Perl_av_fetch(pTHX_ AV* ar, I32 key, I32 lval);
void	Perl_av_fill(pTHX_ AV* ar, I32 fill);
I32	Perl_av_len(pTHX_ AV* ar);
AV*	Perl_av_make(pTHX_ I32 size, SV** svp);
SV*	Perl_av_pop(pTHX_ AV* ar);
void	Perl_av_push(pTHX_ AV* ar, SV* val);
void	Perl_av_reify(pTHX_ AV* ar);
SV*	Perl_av_shift(pTHX_ AV* ar);
SV**	Perl_av_store(pTHX_ AV* ar, I32 key, SV* val);
void	Perl_av_undef(pTHX_ AV* ar);
void	Perl_av_unshift(pTHX_ AV* ar, I32 num);
bool	Perl_avhv_exists_ent(pTHX_ AV *ar, SV* keysv, U32 hash);
SV**	Perl_avhv_fetch_ent(pTHX_ AV *ar, SV* keysv, I32 lval, U32 hash);
HE*	Perl_avhv_iternext(pTHX_ AV *ar);
SV*	Perl_avhv_iterval(pTHX_ AV *ar, HE* entry);
HV*	Perl_avhv_keys(pTHX_ AV *ar);
OP*	Perl_bind_match(pTHX_ I32 type, OP* left, OP* pat);
OP*	Perl_block_end(pTHX_ I32 floor, OP* seq);
I32	Perl_block_gimme(pTHX);
int	Perl_block_start(pTHX_ int full);
void	Perl_boot_core_UNIVERSAL(pTHX);
void*	Perl_bset_obj_store(pTHX_ void *obj, I32 ix);
I32	Perl_call_argv(pTHX_ const char* sub_name, I32 flags, char** argv);
void	Perl_call_atexit(pTHX_ ATEXIT_t fn, void *ptr);
void	Perl_call_list(pTHX_ I32 oldscope, AV* av_list);
I32	Perl_call_method(pTHX_ const char* methname, I32 flags);
I32	Perl_call_pv(pTHX_ const char* sub_name, I32 flags);
I32	Perl_call_sv(pTHX_ SV* sv, I32 flags);
#if defined(MYMALLOC)
Malloc_t	Perl_calloc(pTHX_ MEM_SIZE elements, MEM_SIZE size);
#endif
I32	Perl_cando(pTHX_ I32 bit, I32 effective, Stat_t* statbufp);
I32	Perl_cast_i32(pTHX_ double f);
IV	Perl_cast_iv(pTHX_ double f);
U32	Perl_cast_ulong(pTHX_ double f);
UV	Perl_cast_uv(pTHX_ double f);
#if defined(USE_THREADS)
MAGIC*	Perl_condpair_magic(pTHX_ SV *sv);
#endif
OP*	Perl_convert(pTHX_ I32 optype, I32 flags, OP* o);
void	Perl_croak(pTHX_ const char* pat, ...) __attribute__((noreturn));
void	Perl_cv_ckproto(pTHX_ CV* cv, GV* gv, char* p);
CV*	Perl_cv_clone(pTHX_ CV* proto);
SV*	Perl_cv_const_sv(pTHX_ CV* cv);
void	Perl_cv_undef(pTHX_ CV* cv);
void	Perl_cx_dump(pTHX_ PERL_CONTEXT* cs);
I32	Perl_cxinc(pTHX);
void	Perl_deb(pTHX_ const char* pat, ...);
void	Perl_deb_growlevel(pTHX);
I32	Perl_debop(pTHX_ OP* o);
void	Perl_debprofdump(pTHX);
I32	Perl_debstack(pTHX);
I32	Perl_debstackptrs(pTHX);
void*	Perl_default_protect(pTHX_ int *excpt, protect_body_t body, ...);
char*	Perl_delimcpy(pTHX_ char* to, char* toend, char* from, char* fromend, int delim, I32* retlen);
void	Perl_deprecate(pTHX_ char* s);
OP*	Perl_die(pTHX_ const char* pat, ...);
OP*	Perl_die_where(pTHX_ char* message, STRLEN msglen);
bool	Perl_do_aexec(pTHX_ SV* really, SV** mark, SV** sp);
int	Perl_do_binmode(pTHX_ PerlIO *fp, int iotype, int flag);
I32	Perl_do_chomp(pTHX_ SV* sv);
void	Perl_do_chop(pTHX_ SV* asv, SV* sv);
bool	Perl_do_close(pTHX_ GV* gv, bool not_implicit);
bool	Perl_do_eof(pTHX_ GV* gv);
bool	Perl_do_exec(pTHX_ char* cmd);
#if !defined(WIN32)
bool	Perl_do_exec3(pTHX_ char* cmd, int fd, int flag);
#endif
void	Perl_do_execfree(pTHX);
void	Perl_do_gv_dump(pTHX_ I32 level, PerlIO *file, char *name, GV *sv);
void	Perl_do_gvgv_dump(pTHX_ I32 level, PerlIO *file, char *name, GV *sv);
void	Perl_do_hv_dump(pTHX_ I32 level, PerlIO *file, char *name, HV *sv);
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
I32	Perl_do_ipcctl(pTHX_ I32 optype, SV** mark, SV** sp);
#endif
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
I32	Perl_do_ipcget(pTHX_ I32 optype, SV** mark, SV** sp);
#endif
void	Perl_do_join(pTHX_ SV* sv, SV* del, SV** mark, SV** sp);
OP*	Perl_do_kv(pTHX_ ARGSproto);
void	Perl_do_magic_dump(pTHX_ I32 level, PerlIO *file, MAGIC *mg, I32 nest, I32 maxnest, bool dumpops, STRLEN pvlim);
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
I32	Perl_do_msgrcv(pTHX_ SV** mark, SV** sp);
#endif
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
I32	Perl_do_msgsnd(pTHX_ SV** mark, SV** sp);
#endif
void	Perl_do_op_dump(pTHX_ I32 level, PerlIO *file, OP *o);
bool	Perl_do_open(pTHX_ GV* gv, char* name, I32 len, int as_raw, int rawmode, int rawperm, PerlIO* supplied_fp);
void	Perl_do_pipe(pTHX_ SV* sv, GV* rgv, GV* wgv);
void	Perl_do_pmop_dump(pTHX_ I32 level, PerlIO *file, PMOP *pm);
bool	Perl_do_print(pTHX_ SV* sv, PerlIO* fp);
OP*	Perl_do_readline(pTHX);
bool	Perl_do_seek(pTHX_ GV* gv, Off_t pos, int whence);
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
I32	Perl_do_semop(pTHX_ SV** mark, SV** sp);
#endif
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
I32	Perl_do_shmio(pTHX_ I32 optype, SV** mark, SV** sp);
#endif
void	Perl_do_sprintf(pTHX_ SV* sv, I32 len, SV** sarg);
void	Perl_do_sv_dump(pTHX_ I32 level, PerlIO *file, SV *sv, I32 nest, I32 maxnest, bool dumpops, STRLEN pvlim);
Off_t	Perl_do_sysseek(pTHX_ GV* gv, Off_t pos, int whence);
Off_t	Perl_do_tell(pTHX_ GV* gv);
I32	Perl_do_trans(pTHX_ SV* sv);
void	Perl_do_vecset(pTHX_ SV* sv);
void	Perl_do_vop(pTHX_ I32 optype, SV* sv, SV* left, SV* right);
OP*	Perl_dofile(pTHX_ OP* term);
void	Perl_dounwind(pTHX_ I32 cxix);
I32	Perl_dowantarray(pTHX);
void	Perl_dump_all(pTHX);
void	Perl_dump_eval(pTHX);
#if defined(DUMP_FDS)
void	Perl_dump_fds(pTHX_ char* s);
#endif
void	Perl_dump_form(pTHX_ GV* gv);
void	Perl_dump_indent(pTHX_ I32 level, PerlIO *file, const char* pat, ...);
#if defined(MYMALLOC)
void	Perl_dump_mstats(pTHX_ char* s);
#endif
void	Perl_dump_packsubs(pTHX_ HV* stash);
void	Perl_dump_sub(pTHX_ GV* gv);
SV*	Perl_eval_pv(pTHX_ const char* p, I32 croak_on_error);
I32	Perl_eval_sv(pTHX_ SV* sv, I32 flags);
void	Perl_fbm_compile(pTHX_ SV* sv, U32 flags);
char*	Perl_fbm_instr(pTHX_ unsigned char* big, unsigned char* bigend, SV* littlesv, U32 flags);
SV*	Perl_filter_add(pTHX_ filter_t funcp, SV* datasv);
void	Perl_filter_del(pTHX_ filter_t funcp);
I32	Perl_filter_read(pTHX_ int idx, SV* buffer, int maxlen);
char*	Perl_find_script(pTHX_ char *scriptname, bool dosearch, char **search_ext, I32 flags);
#if defined(USE_THREADS)
PADOFFSET	Perl_find_threadsv(pTHX_ const char *name);
#endif
OP*	Perl_fold_constants(pTHX_ OP* arg);
OP*	Perl_force_list(pTHX_ OP* arg);
char*	Perl_form(pTHX_ const char* pat, ...);
void	Perl_free_tmps(pTHX);
OP*	Perl_gen_constant_list(pTHX_ OP* o);
AV*	Perl_get_av(pTHX_ const char* name, I32 create);
CV*	Perl_get_cv(pTHX_ const char* name, I32 create);
HV*	Perl_get_hv(pTHX_ const char* name, I32 create);
char*	Perl_get_no_modify(pTHX);
char**	Perl_get_op_descs(pTHX);
char**	Perl_get_op_names(pTHX);
U32*	Perl_get_opargs(pTHX);
SV*	Perl_get_sv(pTHX_ const char* name, I32 create);
MGVTBL*	Perl_get_vtbl(pTHX_ int vtbl_id);
#if !defined(HAS_GETENV_LEN)
char*	Perl_getenv_len(pTHX_ char* key, unsigned long *len);
#endif
void	Perl_gp_free(pTHX_ GV* gv);
GP*	Perl_gp_ref(pTHX_ GP* gp);
GV*	Perl_gv_AVadd(pTHX_ GV* gv);
GV*	Perl_gv_HVadd(pTHX_ GV* gv);
GV*	Perl_gv_IOadd(pTHX_ GV* gv);
GV*	Perl_gv_autoload4(pTHX_ HV* stash, const char* name, STRLEN len, I32 method);
void	Perl_gv_check(pTHX_ HV* stash);
void	Perl_gv_dump(pTHX_ GV* gv);
void	Perl_gv_efullname(pTHX_ SV* sv, GV* gv);
void	Perl_gv_efullname3(pTHX_ SV* sv, GV* gv, const char* prefix);
GV*	Perl_gv_fetchfile(pTHX_ const char* name);
GV*	Perl_gv_fetchmeth(pTHX_ HV* stash, const char* name, STRLEN len, I32 level);
GV*	Perl_gv_fetchmethod(pTHX_ HV* stash, const char* name);
GV*	Perl_gv_fetchmethod_autoload(pTHX_ HV* stash, const char* name, I32 autoload);
GV*	Perl_gv_fetchpv(pTHX_ const char* name, I32 add, I32 sv_type);
void	Perl_gv_fullname(pTHX_ SV* sv, GV* gv);
void	Perl_gv_fullname3(pTHX_ SV* sv, GV* gv, const char* prefix);
void	Perl_gv_init(pTHX_ GV* gv, HV* stash, const char* name, STRLEN len, int multi);
HV*	Perl_gv_stashpv(pTHX_ const char* name, I32 create);
HV*	Perl_gv_stashpvn(pTHX_ const char* name, U32 namelen, I32 create);
HV*	Perl_gv_stashsv(pTHX_ SV* sv, I32 create);
void	Perl_hv_clear(pTHX_ HV* tb);
void	Perl_hv_delayfree_ent(pTHX_ HV* hv, HE* entry);
SV*	Perl_hv_delete(pTHX_ HV* tb, const char* key, U32 klen, I32 flags);
SV*	Perl_hv_delete_ent(pTHX_ HV* tb, SV* key, I32 flags, U32 hash);
bool	Perl_hv_exists(pTHX_ HV* tb, const char* key, U32 klen);
bool	Perl_hv_exists_ent(pTHX_ HV* tb, SV* key, U32 hash);
SV**	Perl_hv_fetch(pTHX_ HV* tb, const char* key, U32 klen, I32 lval);
HE*	Perl_hv_fetch_ent(pTHX_ HV* tb, SV* key, I32 lval, U32 hash);
void	Perl_hv_free_ent(pTHX_ HV* hv, HE* entry);
I32	Perl_hv_iterinit(pTHX_ HV* tb);
char*	Perl_hv_iterkey(pTHX_ HE* entry, I32* retlen);
SV*	Perl_hv_iterkeysv(pTHX_ HE* entry);
HE*	Perl_hv_iternext(pTHX_ HV* tb);
SV*	Perl_hv_iternextsv(pTHX_ HV* hv, char** key, I32* retlen);
SV*	Perl_hv_iterval(pTHX_ HV* tb, HE* entry);
void	Perl_hv_ksplit(pTHX_ HV* hv, IV newmax);
void	Perl_hv_magic(pTHX_ HV* hv, GV* gv, int how);
SV**	Perl_hv_store(pTHX_ HV* tb, const char* key, U32 klen, SV* val, U32 hash);
HE*	Perl_hv_store_ent(pTHX_ HV* tb, SV* key, SV* val, U32 hash);
void	Perl_hv_undef(pTHX_ HV* tb);
I32	Perl_ibcmp(pTHX_ const char* a, const char* b, I32 len);
I32	Perl_ibcmp_locale(pTHX_ const char* a, const char* b, I32 len);
I32	Perl_ingroup(pTHX_ I32 testgid, I32 effective);
int	Perl_init_i18nl10n(pTHX_ int printwarn);
int	Perl_init_i18nl14n(pTHX_ int printwarn);
void	Perl_init_stacks(pTHX_ ARGSproto);
char*	Perl_instr(pTHX_ const char* big, const char* little);
U32	Perl_intro_my(pTHX);
OP*	Perl_invert(pTHX_ OP* cmd);
bool	Perl_io_close(pTHX_ IO* io);
bool	Perl_is_uni_alnum(pTHX_ U32 c);
bool	Perl_is_uni_alnum_lc(pTHX_ U32 c);
bool	Perl_is_uni_alpha(pTHX_ U32 c);
bool	Perl_is_uni_alpha_lc(pTHX_ U32 c);
bool	Perl_is_uni_digit(pTHX_ U32 c);
bool	Perl_is_uni_digit_lc(pTHX_ U32 c);
bool	Perl_is_uni_idfirst(pTHX_ U32 c);
bool	Perl_is_uni_idfirst_lc(pTHX_ U32 c);
bool	Perl_is_uni_lower(pTHX_ U32 c);
bool	Perl_is_uni_lower_lc(pTHX_ U32 c);
bool	Perl_is_uni_print(pTHX_ U32 c);
bool	Perl_is_uni_print_lc(pTHX_ U32 c);
bool	Perl_is_uni_space(pTHX_ U32 c);
bool	Perl_is_uni_space_lc(pTHX_ U32 c);
bool	Perl_is_uni_upper(pTHX_ U32 c);
bool	Perl_is_uni_upper_lc(pTHX_ U32 c);
bool	Perl_is_utf8_alnum(pTHX_ U8 *p);
bool	Perl_is_utf8_alpha(pTHX_ U8 *p);
bool	Perl_is_utf8_digit(pTHX_ U8 *p);
bool	Perl_is_utf8_idfirst(pTHX_ U8 *p);
bool	Perl_is_utf8_lower(pTHX_ U8 *p);
bool	Perl_is_utf8_mark(pTHX_ U8 *p);
bool	Perl_is_utf8_print(pTHX_ U8 *p);
bool	Perl_is_utf8_space(pTHX_ U8 *p);
bool	Perl_is_utf8_upper(pTHX_ U8 *p);
OP*	Perl_jmaybe(pTHX_ OP* arg);
I32	Perl_keyword(pTHX_ char* d, I32 len);
void	Perl_leave_scope(pTHX_ I32 base);
void	Perl_lex_end(pTHX);
void	Perl_lex_start(pTHX_ SV* line);
OP*	Perl_linklist(pTHX_ OP* o);
OP*	Perl_list(pTHX_ OP* o);
OP*	Perl_listkids(pTHX_ OP* o);
OP*	Perl_localize(pTHX_ OP* arg, I32 lexical);
I32	Perl_looks_like_number(pTHX_ SV* sv);
int	Perl_magic_clear_all_env(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_clearenv(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_clearpack(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_clearsig(pTHX_ SV* sv, MAGIC* mg);
void	Perl_magic_dump(pTHX_ MAGIC *mg);
int	Perl_magic_existspack(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_freeregexp(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_get(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_getarylen(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_getdefelem(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_getglob(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_getnkeys(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_getpack(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_getpos(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_getsig(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_getsubstr(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_gettaint(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_getuvar(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_getvec(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_killbackrefs(pTHX_ SV *sv, MAGIC *mg);
U32	Perl_magic_len(pTHX_ SV* sv, MAGIC* mg);
#if defined(USE_THREADS)
int	Perl_magic_mutexfree(pTHX_ SV* sv, MAGIC* mg);
#endif
int	Perl_magic_nextpack(pTHX_ SV* sv, MAGIC* mg, SV* key);
U32	Perl_magic_regdata_cnt(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_regdatum_get(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_set(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_set_all_env(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setamagic(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setarylen(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setbm(pTHX_ SV* sv, MAGIC* mg);
#if defined(USE_LOCALE_COLLATE)
int	Perl_magic_setcollxfrm(pTHX_ SV* sv, MAGIC* mg);
#endif
int	Perl_magic_setdbline(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setdefelem(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setenv(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setfm(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setglob(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setisa(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setmglob(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setnkeys(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setpack(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setpos(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setsig(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setsubstr(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_settaint(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setuvar(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_setvec(pTHX_ SV* sv, MAGIC* mg);
U32	Perl_magic_sizepack(pTHX_ SV* sv, MAGIC* mg);
int	Perl_magic_wipepack(pTHX_ SV* sv, MAGIC* mg);
void	Perl_magicname(pTHX_ char* sym, char* name, I32 namlen);
int	main(int argc, char** argv, char** env);
#if defined(MYMALLOC)
Malloc_t	Perl_malloc(pTHX_ MEM_SIZE nbytes);
#endif
#if defined(MYMALLOC)
MEM_SIZE	Perl_malloced_size(pTHX_ void *p);
#endif
void	Perl_markstack_grow(pTHX);
#if defined(USE_LOCALE_COLLATE)
char*	Perl_mem_collxfrm(pTHX_ const char* s, STRLEN len, STRLEN* xlen);
#endif
SV*	Perl_mess(pTHX_ const char* pat, va_list* args);
#if defined(MYMALLOC)
Free_t	Perl_mfree(pTHX_ Malloc_t where);
#endif
int	Perl_mg_clear(pTHX_ SV* sv);
int	Perl_mg_copy(pTHX_ SV* sv, SV* nsv, const char* key, I32 klen);
MAGIC*	Perl_mg_find(pTHX_ SV* sv, int type);
int	Perl_mg_free(pTHX_ SV* sv);
int	Perl_mg_get(pTHX_ SV* sv);
U32	Perl_mg_length(pTHX_ SV* sv);
void	Perl_mg_magical(pTHX_ SV* sv);
int	Perl_mg_set(pTHX_ SV* sv);
I32	Perl_mg_size(pTHX_ SV* sv);
OP*	Perl_mod(pTHX_ OP* o, I32 type);
char*	Perl_moreswitches(pTHX_ char* s);
OP*	Perl_my(pTHX_ OP* o);
#if !defined(HAS_BCOPY) || !defined(HAS_SAFE_BCOPY)
char*	Perl_my_bcopy(pTHX_ const char* from, char* to, I32 len);
#endif
#if !defined(HAS_BZERO) && !defined(HAS_MEMSET)
char*	Perl_my_bzero(pTHX_ char* loc, I32 len);
#endif
#if !defined(HAS_TRUNCATE) && !defined(HAS_CHSIZE) && defined(F_FREESP)
I32	Perl_my_chsize(pTHX_ int fd, Off_t length);
#endif
void	Perl_my_exit(pTHX_ U32 status) __attribute__((noreturn));
void	Perl_my_failure_exit(pTHX) __attribute__((noreturn));
I32	Perl_my_fflush_all(pTHX);
#if defined(MYSWAP)
long	Perl_my_htonl(pTHX_ long l);
#endif
I32	Perl_my_lstat(pTHX_ ARGSproto);
#if !defined(HAS_MEMCMP) || !defined(HAS_SANE_MEMCMP)
I32	Perl_my_memcmp(pTHX_ const char* s1, const char* s2, I32 len);
#endif
#if !defined(HAS_MEMSET)
void*	Perl_my_memset(pTHX_ char* loc, I32 ch, I32 len);
#endif
#if defined(MYSWAP)
long	Perl_my_ntohl(pTHX_ long l);
#endif
#if !defined(PERL_OBJECT)
I32	Perl_my_pclose(pTHX_ PerlIO* ptr);
#endif
#if !defined(PERL_OBJECT)
PerlIO*	Perl_my_popen(pTHX_ char* cmd, char* mode);
#endif
void	Perl_my_setenv(pTHX_ char* nam, char* val);
I32	Perl_my_stat(pTHX_ ARGSproto);
#if defined(MYSWAP)
short	Perl_my_swap(pTHX_ short s);
#endif
void	Perl_my_unexec(pTHX);
OP*	Perl_newANONHASH(pTHX_ OP* o);
OP*	Perl_newANONLIST(pTHX_ OP* o);
OP*	Perl_newANONSUB(pTHX_ I32 floor, OP* proto, OP* block);
OP*	Perl_newASSIGNOP(pTHX_ I32 flags, OP* left, I32 optype, OP* right);
AV*	Perl_newAV(pTHX);
OP*	Perl_newAVREF(pTHX_ OP* o);
OP*	Perl_newBINOP(pTHX_ I32 type, I32 flags, OP* first, OP* last);
OP*	Perl_newCONDOP(pTHX_ I32 flags, OP* expr, OP* trueop, OP* falseop);
void	Perl_newCONSTSUB(pTHX_ HV* stash, char* name, SV* sv);
OP*	Perl_newCVREF(pTHX_ I32 flags, OP* o);
void	Perl_newFORM(pTHX_ I32 floor, OP* o, OP* block);
OP*	Perl_newFOROP(pTHX_ I32 flags, char* label, line_t forline, OP* sclr, OP* expr, OP*block, OP*cont);
OP*	Perl_newGVOP(pTHX_ I32 type, I32 flags, GV* gv);
OP*	Perl_newGVREF(pTHX_ I32 type, OP* o);
GV*	Perl_newGVgen(pTHX_ char* pack);
HV*	Perl_newHV(pTHX);
OP*	Perl_newHVREF(pTHX_ OP* o);
HV*	Perl_newHVhv(pTHX_ HV* hv);
IO*	Perl_newIO(pTHX);
OP*	Perl_newLISTOP(pTHX_ I32 type, I32 flags, OP* first, OP* last);
OP*	Perl_newLOGOP(pTHX_ I32 optype, I32 flags, OP* left, OP* right);
OP*	Perl_newLOOPEX(pTHX_ I32 type, OP* label);
OP*	Perl_newLOOPOP(pTHX_ I32 flags, I32 debuggable, OP* expr, OP* block);
OP*	Perl_newNULLLIST(pTHX);
OP*	Perl_newOP(pTHX_ I32 optype, I32 flags);
OP*	Perl_newPMOP(pTHX_ I32 type, I32 flags);
void	Perl_newPROG(pTHX_ OP* o);
OP*	Perl_newPVOP(pTHX_ I32 type, I32 flags, char* pv);
OP*	Perl_newRANGE(pTHX_ I32 flags, OP* left, OP* right);
SV*	Perl_newRV(pTHX_ SV* pref);
SV*	Perl_newRV_noinc(pTHX_ SV *sv);
OP*	Perl_newSLICEOP(pTHX_ I32 flags, OP* subscript, OP* listop);
OP*	Perl_newSTATEOP(pTHX_ I32 flags, char* label, OP* o);
CV*	Perl_newSUB(pTHX_ I32 floor, OP* o, OP* proto, OP* block);
SV*	Perl_newSV(pTHX_ STRLEN len);
OP*	Perl_newSVOP(pTHX_ I32 type, I32 flags, SV* sv);
OP*	Perl_newSVREF(pTHX_ OP* o);
SV*	Perl_newSViv(pTHX_ IV i);
SV*	Perl_newSVnv(pTHX_ double n);
SV*	Perl_newSVpv(pTHX_ const char* s, STRLEN len);
SV*	Perl_newSVpvf(pTHX_ const char* pat, ...);
SV*	Perl_newSVpvn(pTHX_ const char* s, STRLEN len);
SV*	Perl_newSVrv(pTHX_ SV* rv, const char* classname);
SV*	Perl_newSVsv(pTHX_ SV* old);
OP*	Perl_newUNOP(pTHX_ I32 type, I32 flags, OP* first);
OP*	Perl_newWHILEOP(pTHX_ I32 flags, I32 debuggable, LOOP* loop, I32 whileline, OP* expr, OP* block, OP* cont);
CV*	Perl_newXS(pTHX_ char* name, XSUBADDR_t f, char* filename);
void	Perl_new_collate(pTHX_ const char* newcoll);
void	Perl_new_ctype(pTHX_ const char* newctype);
void	Perl_new_numeric(pTHX_ const char* newcoll);
PERL_SI*	Perl_new_stackinfo(pTHX_ I32 stitems, I32 cxitems);
#if defined(USE_THREADS)
struct perl_thread*	Perl_new_struct_thread(pTHX_ struct perl_thread *t);
#endif
PerlIO*	Perl_nextargv(pTHX_ GV* gv);
char*	Perl_ninstr(pTHX_ const char* big, const char* bigend, const char* little, const char* lend);
OP*	Perl_oopsAV(pTHX_ OP* o);
OP*	Perl_oopsCV(pTHX_ OP* o);
OP*	Perl_oopsHV(pTHX_ OP* o);
SV*	Perl_op_const_sv(pTHX_ OP* o, CV* cv);
void	Perl_op_dump(pTHX_ OP* arg);
void	Perl_op_free(pTHX_ OP* arg);
void	Perl_package(pTHX_ OP* o);
PADOFFSET	Perl_pad_alloc(pTHX_ I32 optype, U32 tmptype);
PADOFFSET	Perl_pad_allocmy(pTHX_ char* name);
PADOFFSET	Perl_pad_findmy(pTHX_ char* name);
void	Perl_pad_free(pTHX_ PADOFFSET po);
void	Perl_pad_leavemy(pTHX_ I32 fill);
void	Perl_pad_reset(pTHX);
SV*	Perl_pad_sv(pTHX_ PADOFFSET po);
void	Perl_pad_swipe(pTHX_ PADOFFSET po);
void	Perl_peep(pTHX_ OP* o);
#if !defined(PERL_OBJECT)
PerlInterpreter*	perl_alloc(void);
#endif
void	perl_construct(PerlInterpreter* sv_interp);
void	perl_destruct(PerlInterpreter* sv_interp);
void	perl_free(PerlInterpreter* sv_interp);
int	perl_parse(PerlInterpreter* sv_interp, XSINIT_t xsinit, int argc, char** argv, char** env);
int	perl_run(PerlInterpreter* sv_interp);
void	Perl_pidgone(pTHX_ int pid, int status);
void	Perl_pmflag(pTHX_ U16* pmfl, int ch);
void	Perl_pmop_dump(pTHX_ PMOP* pm);
OP*	Perl_pmruntime(pTHX_ OP* pm, OP* expr, OP* repl);
OP*	Perl_pmtrans(pTHX_ OP* o, OP* expr, OP* repl);
OP*	Perl_pop_return(pTHX);
void	Perl_pop_scope(pTHX);
regexp*	Perl_pregcomp(pTHX_ char* exp, char* xend, PMOP* pm);
I32	Perl_pregexec(pTHX_ regexp* prog, char* stringarg, char* strend, char* strbeg, I32 minend, SV* screamer, U32 nosave);
void	Perl_pregfree(pTHX_ struct regexp* r);
OP*	Perl_prepend_elem(pTHX_ I32 optype, OP* head, OP* tail);
void	Perl_push_return(pTHX_ OP* o);
void	Perl_push_scope(pTHX);
char*	Perl_pv_display(pTHX_ SV *sv, char *pv, STRLEN cur, STRLEN len, STRLEN pvlim);
#if defined(MYMALLOC)
Malloc_t	Perl_realloc(pTHX_ Malloc_t where, MEM_SIZE nbytes);
#endif
OP*	Perl_ref(pTHX_ OP* o, I32 type);
OP*	Perl_refkids(pTHX_ OP* o, I32 type);
void	Perl_regdump(pTHX_ regexp* r);
I32	Perl_regexec_flags(pTHX_ regexp* prog, char* stringarg, char* strend, char* strbeg, I32 minend, SV* screamer, void* data, U32 flags);
void	Perl_reginitcolors(pTHX);
regnode*	Perl_regnext(pTHX_ regnode* p);
void	Perl_regprop(pTHX_ SV* sv, regnode* o);
void	Perl_repeatcpy(pTHX_ char* to, const char* from, I32 len, I32 count);
void	Perl_require_pv(pTHX_ const char* pv);
char*	Perl_rninstr(pTHX_ const char* big, const char* bigend, const char* little, const char* lend);
Sighandler_t	Perl_rsignal(pTHX_ int i, Sighandler_t t);
int	Perl_rsignal_restore(pTHX_ int i, Sigsave_t* t);
int	Perl_rsignal_save(pTHX_ int i, Sighandler_t t1, Sigsave_t* t2);
Sighandler_t	Perl_rsignal_state(pTHX_ int i);
int	Perl_runops_debug(pTHX);
int	Perl_runops_standard(pTHX);
void	Perl_rxres_free(pTHX_ void** rsp);
void	Perl_rxres_restore(pTHX_ void** rsp, REGEXP* prx);
void	Perl_rxres_save(pTHX_ void** rsp, REGEXP* prx);
Malloc_t	Perl_safesyscalloc(pTHX_ MEM_SIZE elements, MEM_SIZE size);
Free_t	Perl_safesysfree(pTHX_ Malloc_t where);
Malloc_t	Perl_safesysmalloc(pTHX_ MEM_SIZE nbytes);
Malloc_t	Perl_safesysrealloc(pTHX_ Malloc_t where, MEM_SIZE nbytes);
#if defined(LEAKTEST)
Malloc_t	Perl_safexcalloc(pTHX_ I32 x, MEM_SIZE elements, MEM_SIZE size);
#endif
#if defined(LEAKTEST)
void	Perl_safexfree(pTHX_ Malloc_t where);
#endif
#if defined(LEAKTEST)
Malloc_t	Perl_safexmalloc(pTHX_ I32 x, MEM_SIZE size);
#endif
#if defined(LEAKTEST)
Malloc_t	Perl_safexrealloc(pTHX_ Malloc_t where, MEM_SIZE size);
#endif
#if !defined(HAS_RENAME)
I32	Perl_same_dirent(pTHX_ char* a, char* b);
#endif
void	Perl_save_I16(pTHX_ I16* intp);
void	Perl_save_I32(pTHX_ I32* intp);
void	Perl_save_aelem(pTHX_ AV* av, I32 idx, SV **sptr);
I32	Perl_save_alloc(pTHX_ I32 size, I32 pad);
void	Perl_save_aptr(pTHX_ AV** aptr);
AV*	Perl_save_ary(pTHX_ GV* gv);
void	Perl_save_clearsv(pTHX_ SV** svp);
void	Perl_save_delete(pTHX_ HV* hv, char* key, I32 klen);
void	Perl_save_destructor(pTHX_ DESTRUCTORFUNC_t f, void* p);
void	Perl_save_freeop(pTHX_ OP* o);
void	Perl_save_freepv(pTHX_ char* pv);
void	Perl_save_freesv(pTHX_ SV* sv);
void	Perl_save_generic_svref(pTHX_ SV** sptr);
void	Perl_save_gp(pTHX_ GV* gv, I32 empty);
HV*	Perl_save_hash(pTHX_ GV* gv);
void	Perl_save_helem(pTHX_ HV* hv, SV *key, SV **sptr);
void	Perl_save_hints(pTHX);
void	Perl_save_hptr(pTHX_ HV** hptr);
void	Perl_save_int(pTHX_ int* intp);
void	Perl_save_item(pTHX_ SV* item);
void	Perl_save_iv(pTHX_ IV* iv);
void	Perl_save_list(pTHX_ SV** sarg, I32 maxsarg);
void	Perl_save_long(pTHX_ long* longp);
void	Perl_save_nogv(pTHX_ GV* gv);
void	Perl_save_op(pTHX);
void	Perl_save_pptr(pTHX_ char** pptr);
void	Perl_save_re_context(pTHX);
SV*	Perl_save_scalar(pTHX_ GV* gv);
void	Perl_save_sptr(pTHX_ SV** sptr);
SV*	Perl_save_svref(pTHX_ SV** sptr);
SV**	Perl_save_threadsv(pTHX_ PADOFFSET i);
char*	Perl_savepv(pTHX_ const char* sv);
char*	Perl_savepvn(pTHX_ const char* sv, I32 len);
void	Perl_savestack_grow(pTHX);
OP*	Perl_sawparens(pTHX_ OP* o);
OP*	Perl_scalar(pTHX_ OP* o);
OP*	Perl_scalarkids(pTHX_ OP* o);
OP*	Perl_scalarseq(pTHX_ OP* o);
OP*	Perl_scalarvoid(pTHX_ OP* o);
UV	Perl_scan_bin(pTHX_ char* start, I32 len, I32* retlen);
UV	Perl_scan_hex(pTHX_ char* start, I32 len, I32* retlen);
char*	Perl_scan_num(pTHX_ char* s);
UV	Perl_scan_oct(pTHX_ char* start, I32 len, I32* retlen);
OP*	Perl_scope(pTHX_ OP* o);
char*	Perl_screaminstr(pTHX_ SV* bigsv, SV* littlesv, I32 start_shift, I32 end_shift, I32 *state, I32 last);
void	Perl_set_numeric_local(pTHX);
void	Perl_set_numeric_standard(pTHX);
void	Perl_setdefout(pTHX_ GV* gv);
#if !defined(VMS)
I32	Perl_setenv_getix(pTHX_ char* nam);
#endif
HEK*	Perl_share_hek(pTHX_ const char* sv, I32 len, U32 hash);
char*	Perl_sharepvn(pTHX_ const char* sv, I32 len, U32 hash);
Signal_t	Perl_sighandler(pTHX_ int sig);
SV**	Perl_stack_grow(pTHX_ SV** sp, SV**p, int n);
I32	Perl_start_subparse(pTHX_ I32 is_format, U32 flags);
void	Perl_sub_crush_depth(pTHX_ CV* cv);
bool	Perl_sv_2bool(pTHX_ SV* sv);
CV*	Perl_sv_2cv(pTHX_ SV* sv, HV** st, GV** gvp, I32 lref);
IO*	Perl_sv_2io(pTHX_ SV* sv);
IV	Perl_sv_2iv(pTHX_ SV* sv);
SV*	Perl_sv_2mortal(pTHX_ SV* sv);
double	Perl_sv_2nv(pTHX_ SV* sv);
char*	Perl_sv_2pv(pTHX_ SV* sv, STRLEN* lp);
char*	Perl_sv_2pv_nolen(pTHX_ SV* sv);
UV	Perl_sv_2uv(pTHX_ SV* sv);
void	Perl_sv_add_arena(pTHX_ char* ptr, U32 size, U32 flags);
int	Perl_sv_backoff(pTHX_ SV* sv);
SV*	Perl_sv_bless(pTHX_ SV* sv, HV* stash);
void	Perl_sv_catpv(pTHX_ SV* sv, const char* ptr);
void	Perl_sv_catpv_mg(pTHX_ SV *sv, const char *ptr);
void	Perl_sv_catpvf(pTHX_ SV* sv, const char* pat, ...);
void	Perl_sv_catpvf_mg(pTHX_ SV *sv, const char* pat, ...);
void	Perl_sv_catpvn(pTHX_ SV* sv, const char* ptr, STRLEN len);
void	Perl_sv_catpvn_mg(pTHX_ SV *sv, const char *ptr, STRLEN len);
void	Perl_sv_catsv(pTHX_ SV* dsv, SV* ssv);
void	Perl_sv_catsv_mg(pTHX_ SV *dstr, SV *sstr);
void	Perl_sv_chop(pTHX_ SV* sv, char* ptr);
void	Perl_sv_clean_all(pTHX);
void	Perl_sv_clean_objs(pTHX);
void	Perl_sv_clear(pTHX_ SV* sv);
I32	Perl_sv_cmp(pTHX_ SV* sv1, SV* sv2);
I32	Perl_sv_cmp_locale(pTHX_ SV* sv1, SV* sv2);
#if defined(USE_LOCALE_COLLATE)
char*	Perl_sv_collxfrm(pTHX_ SV* sv, STRLEN* nxp);
#endif
OP*	Perl_sv_compile_2op(pTHX_ SV* sv, OP** startp, char* code, AV** avp);
void	Perl_sv_dec(pTHX_ SV* sv);
bool	Perl_sv_derived_from(pTHX_ SV* sv, const char* name);
void	Perl_sv_dump(pTHX_ SV* sv);
I32	Perl_sv_eq(pTHX_ SV* sv1, SV* sv2);
void	Perl_sv_force_normal(pTHX_ SV *sv);
void	Perl_sv_free(pTHX_ SV* sv);
void	Perl_sv_free_arenas(pTHX);
char*	Perl_sv_gets(pTHX_ SV* sv, PerlIO* fp, I32 append);
char*	Perl_sv_grow(pTHX_ SV* sv, STRLEN newlen);
void	Perl_sv_inc(pTHX_ SV* sv);
void	Perl_sv_insert(pTHX_ SV* bigsv, STRLEN offset, STRLEN len, char* little, STRLEN littlelen);
int	Perl_sv_isa(pTHX_ SV* sv, const char* name);
int	Perl_sv_isobject(pTHX_ SV* sv);
IV	Perl_sv_iv(pTHX_ SV* sv);
STRLEN	Perl_sv_len(pTHX_ SV* sv);
STRLEN	Perl_sv_len_utf8(pTHX_ SV* sv);
void	Perl_sv_magic(pTHX_ SV* sv, SV* obj, int how, const char* name, I32 namlen);
SV*	Perl_sv_mortalcopy(pTHX_ SV* oldsv);
SV*	Perl_sv_newmortal(pTHX);
SV*	Perl_sv_newref(pTHX_ SV* sv);
double	Perl_sv_nv(pTHX_ SV* sv);
char*	Perl_sv_peek(pTHX_ SV* sv);
void	Perl_sv_pos_b2u(pTHX_ SV* sv, I32* offsetp);
void	Perl_sv_pos_u2b(pTHX_ SV* sv, I32* offsetp, I32* lenp);
char*	Perl_sv_pv(pTHX_ SV *sv);
char*	Perl_sv_pvn(pTHX_ SV *sv, STRLEN *len);
char*	Perl_sv_pvn_force(pTHX_ SV* sv, STRLEN* lp);
char*	Perl_sv_reftype(pTHX_ SV* sv, int ob);
void	Perl_sv_replace(pTHX_ SV* sv, SV* nsv);
void	Perl_sv_report_used(pTHX);
void	Perl_sv_reset(pTHX_ char* s, HV* stash);
SV*	Perl_sv_rvweaken(pTHX_ SV *sv);
void	Perl_sv_setiv(pTHX_ SV* sv, IV num);
void	Perl_sv_setiv_mg(pTHX_ SV *sv, IV i);
void	Perl_sv_setnv(pTHX_ SV* sv, double num);
void	Perl_sv_setnv_mg(pTHX_ SV *sv, double num);
void	Perl_sv_setpv(pTHX_ SV* sv, const char* ptr);
void	Perl_sv_setpv_mg(pTHX_ SV *sv, const char *ptr);
void	Perl_sv_setpvf(pTHX_ SV* sv, const char* pat, ...);
void	Perl_sv_setpvf_mg(pTHX_ SV *sv, const char* pat, ...);
void	Perl_sv_setpviv(pTHX_ SV* sv, IV num);
void	Perl_sv_setpviv_mg(pTHX_ SV *sv, IV iv);
void	Perl_sv_setpvn(pTHX_ SV* sv, const char* ptr, STRLEN len);
void	Perl_sv_setpvn_mg(pTHX_ SV *sv, const char *ptr, STRLEN len);
SV*	Perl_sv_setref_iv(pTHX_ SV* rv, const char* classname, IV iv);
SV*	Perl_sv_setref_nv(pTHX_ SV* rv, const char* classname, double nv);
SV*	Perl_sv_setref_pv(pTHX_ SV* rv, const char* classname, void* pv);
SV*	Perl_sv_setref_pvn(pTHX_ SV* rv, const char* classname, char* pv, STRLEN n);
void	Perl_sv_setsv(pTHX_ SV* dsv, SV* ssv);
void	Perl_sv_setsv_mg(pTHX_ SV *dstr, SV *sstr);
void	Perl_sv_setuv(pTHX_ SV* sv, UV num);
void	Perl_sv_setuv_mg(pTHX_ SV *sv, UV u);
void	Perl_sv_taint(pTHX_ SV* sv);
bool	Perl_sv_tainted(pTHX_ SV* sv);
I32	Perl_sv_true(pTHX_ SV *sv);
int	Perl_sv_unmagic(pTHX_ SV* sv, int type);
void	Perl_sv_unref(pTHX_ SV* sv);
void	Perl_sv_untaint(pTHX_ SV* sv);
bool	Perl_sv_upgrade(pTHX_ SV* sv, U32 mt);
void	Perl_sv_usepvn(pTHX_ SV* sv, char* ptr, STRLEN len);
void	Perl_sv_usepvn_mg(pTHX_ SV *sv, char *ptr, STRLEN len);
UV	Perl_sv_uv(pTHX_ SV* sv);
void	Perl_sv_vcatpvfn(pTHX_ SV* sv, const char* pat, STRLEN patlen, va_list* args, SV** svargs, I32 svmax, bool *used_locale);
void	Perl_sv_vsetpvfn(pTHX_ SV* sv, const char* pat, STRLEN patlen, va_list* args, SV** svargs, I32 svmax, bool *used_locale);
UV	Perl_swash_fetch(pTHX_ SV *sv, U8 *ptr);
SV*	Perl_swash_init(pTHX_ char* pkg, char* name, SV* listsv, I32 minbits, I32 none);
void	Perl_taint_env(pTHX);
void	Perl_taint_proper(pTHX_ const char* f, char* s);
void	Perl_tmps_grow(pTHX_ I32 n);
U32	Perl_to_uni_lower(pTHX_ U32 c);
U32	Perl_to_uni_lower_lc(pTHX_ U32 c);
U32	Perl_to_uni_title(pTHX_ U32 c);
U32	Perl_to_uni_title_lc(pTHX_ U32 c);
U32	Perl_to_uni_upper(pTHX_ U32 c);
U32	Perl_to_uni_upper_lc(pTHX_ U32 c);
UV	Perl_to_utf8_lower(pTHX_ U8 *p);
UV	Perl_to_utf8_title(pTHX_ U8 *p);
UV	Perl_to_utf8_upper(pTHX_ U8 *p);
#if defined(UNLINK_ALL_VERSIONS)
I32	Perl_unlnk(pTHX_ char* f);
#endif
#if defined(USE_THREADS)
void	Perl_unlock_condpair(pTHX_ void* svv);
#endif
void	Perl_unshare_hek(pTHX_ HEK* hek);
void	Perl_unsharepvn(pTHX_ const char* sv, I32 len, U32 hash);
U8*	Perl_utf16_to_utf8(pTHX_ U16* p, U8 *d, I32 bytelen);
U8*	Perl_utf16_to_utf8_reversed(pTHX_ U16* p, U8 *d, I32 bytelen);
I32	Perl_utf8_distance(pTHX_ U8 *a, U8 *b);
U8*	Perl_utf8_hop(pTHX_ U8 *s, I32 off);
UV	Perl_utf8_to_uv(pTHX_ U8 *s, I32* retlen);
void	Perl_utilize(pTHX_ int aver, I32 floor, OP* version, OP* id, OP* arg);
U8*	Perl_uv_to_utf8(pTHX_ U8 *d, UV uv);
void	Perl_vivify_defelem(pTHX_ SV* sv);
void	Perl_vivify_ref(pTHX_ SV* sv, U32 to_what);
I32	Perl_wait4pid(pTHX_ int pid, int* statusp, int flags);
void	Perl_warn(pTHX_ const char* pat, ...);
void	Perl_warner(pTHX_ U32 err, const char* pat, ...);
void	Perl_watch(pTHX_ char** addr);
I32	Perl_whichsig(pTHX_ char* sig);
void	Perl_yydestruct(pTHX_ void *ptr);
int	Perl_yyerror(pTHX_ char* s);
#if !defined(USE_PURE_BISON)
int	Perl_yylex(pTHX);
#endif
int	Perl_yyparse(pTHX);
int	Perl_yywarn(pTHX_ char* s);
#if defined(PL_OP_SLAB_ALLOC) && defined(PERL_IN_OP_C)
STATIC void*	Slab_Alloc(pTHX_ int m, size_t sz);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC I32	add_data(pTHX_ I32 n, char *s);
#endif
#if defined(MYMALLOC) && defined(PERL_IN_MALLOC_C)
STATIC void	add_to_chain(pTHX_ void *p, MEM_SIZE size, MEM_SIZE chip);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC I32	amagic_cmp(pTHX_ SV *str1, SV *str2);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC I32	amagic_cmp_locale(pTHX_ SV *str1, SV *str2);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC I32	amagic_i_ncmp(pTHX_ SV *a, SV *b);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC I32	amagic_ncmp(pTHX_ SV *a, SV *b);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC int	ao(pTHX_ int toketype);
#endif
#if defined(PERL_IN_SV_C)
STATIC IV	asIV(pTHX_ SV* sv);
#endif
#if defined(PERL_IN_SV_C)
STATIC UV	asUV(pTHX_ SV* sv);
#endif
#if defined(PERL_IN_AV_C)
STATIC I32	avhv_index_sv(pTHX_ SV* sv);
#endif
#if defined(PERL_IN_OP_C)
STATIC void	bad_type(pTHX_ I32 n, char *t, char *name, OP *kid);
#endif
#if defined(MYMALLOC) && defined(DEBUGGING) && defined(PERL_IN_MALLOC_C)
STATIC void	botch(pTHX_ char *diag, char *s);
#endif
#if defined(PERL_IN_REGEXEC_C)
STATIC void	cache_re(pTHX_ regexp *prog);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void*	call_body(pTHX_ va_list args);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void*	call_list_body(pTHX_ va_list args);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	call_xbody(pTHX_ OP *myop, int is_eval);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC void	check_uni(pTHX);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC void	checkcomma(pTHX_ char *s, char *name, char *what);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC void	clear_re(pTHX_ void *r);
#endif
#if defined(PERL_IN_OP_C)
STATIC CV*	cv_clone2(pTHX_ CV *proto, CV *outside);
#endif
#if defined(PERL_IN_RUN_C)
STATIC void	debprof(pTHX_ OP *o);
#endif
#if defined(PERL_IN_HV_C)
STATIC void	del_he(pTHX_ HE *p);
#endif
#if defined(DEBUGGING) && defined(PERL_IN_SV_C)
STATIC void	del_sv(pTHX_ SV *p);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	del_xiv(pTHX_ XPVIV* p);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	del_xnv(pTHX_ XPVNV* p);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	del_xpv(pTHX_ XPV* p);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	del_xrv(pTHX_ XRV* p);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC void	depcom(pTHX);
#endif
#if defined(PERL_IN_PP_C)
STATIC int	div128(pTHX_ SV *pnum, bool *done);
#endif
#if defined(WIN32) && defined(PERL_IN_GLOBALS_C)
STATIC int	do_aspawn(pTHX_ void *vreally, void **vmark, void **vsp);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	do_clean_all(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	do_clean_named_objs(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	do_clean_objs(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	do_report_used(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_DOOP_C)
STATIC I32	do_trans_CC_complex(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_DOOP_C)
STATIC I32	do_trans_CC_count(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_DOOP_C)
STATIC I32	do_trans_CC_simple(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_DOOP_C)
STATIC I32	do_trans_CU_simple(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_DOOP_C)
STATIC I32	do_trans_CU_trivial(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_DOOP_C)
STATIC I32	do_trans_UC_simple(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_DOOP_C)
STATIC I32	do_trans_UC_trivial(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_DOOP_C)
STATIC I32	do_trans_UU_complex(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_DOOP_C)
STATIC I32	do_trans_UU_count(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_DOOP_C)
STATIC I32	do_trans_UU_simple(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC OP*	docatch(pTHX_ OP *o);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC void*	docatch_body(pTHX_ va_list args);
#endif
#if defined(PERL_IN_PP_C)
STATIC void	doencodes(pTHX_ SV* sv, char* s, I32 len);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC OP*	doeval(pTHX_ int gimme, OP** startop);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC OP*	dofindlabel(pTHX_ OP *o, char *label, OP **opstack, OP **oplimit);
#endif
#if defined(PERL_IN_PP_SYS_C)
STATIC OP*	doform(pTHX_ CV *cv, GV *gv, OP *retop);
#endif
#if !defined(HAS_MKDIR) || !defined(HAS_RMDIR) && defined(PERL_IN_PP_SYS_C)
STATIC int	dooneliner(pTHX_ char *cmd, char *filename);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC PerlIO *	doopen_pmc(pTHX_ const char *name, const char *mode);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC void	doparseform(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC I32	dopoptoeval(pTHX_ I32 startingblock);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC I32	dopoptolabel(pTHX_ char *label);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC I32	dopoptoloop(pTHX_ I32 startingblock);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC I32	dopoptosub(pTHX_ I32 startingblock);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC I32	dopoptosub_at(pTHX_ PERL_CONTEXT* cxstk, I32 startingblock);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC regnode*	dumpuntil(pTHX_ regnode *start, regnode *node, regnode *last, SV* sv, I32 l);
#endif
#if defined(MYMALLOC) && defined(PERL_IN_MALLOC_C)
STATIC Malloc_t	emergency_sbrk(pTHX_ MEM_SIZE size);
#endif
#if defined(PERL_IN_PP_SYS_C)
STATIC int	emulate_eaccess(pTHX_ const char* path, int mode);
#endif
#if defined(FCNTL_EMULATE_FLOCK) && defined(PERL_IN_PP_SYS_C)
STATIC int	fcntl_emulate_flock(pTHX_ int fd, int operation);
#endif
#if defined(IAMSUID) && defined(PERL_IN_PERL_C)
STATIC int	fd_on_nosuid_fs(pTHX_ int fd);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC char *	filter_gets(pTHX_ SV *sv, PerlIO *fp, STRLEN append);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	find_beginning(pTHX);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	forbid_setid(pTHX_ char *);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC void	force_ident(pTHX_ char *s, int kind);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC void	force_next(pTHX_ I32 type);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC char*	force_version(pTHX_ char *start);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC char*	force_word(pTHX_ char *start, int token, int check_keyword, int allow_pack, int allow_tick);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC void	free_closures(pTHX);
#endif
#if defined(PERL_IN_PP_HOT_C)
STATIC CV*	get_db_sub(pTHX_ SV **svp, CV *cv);
#endif
#if defined(MYMALLOC) && defined(PERL_IN_MALLOC_C)
STATIC void*	get_from_bigger_buckets(pTHX_ int bucket, MEM_SIZE size);
#endif
#if defined(MYMALLOC) && defined(PERL_IN_MALLOC_C)
STATIC void*	get_from_chain(pTHX_ MEM_SIZE size);
#endif
#if defined(MYMALLOC) && defined(PERL_IN_MALLOC_C)
STATIC union overhead *	getpages(pTHX_ int needed, int *nblksp, int bucket);
#endif
#if defined(MYMALLOC) && defined(PERL_IN_MALLOC_C)
STATIC int	getpages_adjacent(pTHX_ int require);
#endif
#if defined(PERL_IN_OP_C)
STATIC char*	gv_ename(pTHX_ GV *gv);
#endif
#if defined(PERL_IN_GV_C)
STATIC void	gv_init_sv(pTHX_ GV *gv, I32 sv_type);
#endif
#if defined(PERL_IN_HV_C)
STATIC void	hfreeentries(pTHX_ HV *hv);
#endif
#if defined(PERL_IN_HV_C)
STATIC void	hsplit(pTHX_ HV *hv);
#endif
#if defined(PERL_IN_HV_C)
STATIC void	hv_magic_check(pTHX_ HV *hv, bool *needs_copy, bool *needs_store);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC char*	incl_perldb(pTHX);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC void	incline(pTHX_ char *s);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	incpush(pTHX_ char *, int);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	init_debugger(pTHX);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	init_ids(pTHX);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	init_interp(pTHX);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	init_lexer(pTHX);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	init_main_stash(pTHX);
#endif
#if defined(USE_THREADS) && defined(PERL_IN_PERL_C)
STATIC struct perl_thread *	init_main_thread(pTHX);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	init_perllib(pTHX);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	init_postdump_symbols(pTHX_ int, char **, char **);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	init_predump_symbols(pTHX);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC int	intuit_method(pTHX_ char *s, GV *gv);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC int	intuit_more(pTHX_ char *s);
#endif
#if defined(PERL_IN_PP_C)
STATIC SV*	is_an_int(pTHX_ char *s, STRLEN l);
#endif
#if defined(PERL_IN_OP_C)
STATIC bool	is_handle_constructor(pTHX_ OP *o, I32 argnum);
#endif
#if defined(PERL_IN_UNIVERSAL_C)
STATIC SV*	isa_lookup(pTHX_ HV *stash, const char *name, int len, int level);
#endif
#if defined(PERL_IN_OP_C)
STATIC I32	list_assignment(pTHX_ OP *o);
#endif
#if defined(LOCKF_EMULATE_FLOCK) && defined(PERL_IN_PP_SYS_C)
STATIC int	lockf_emulate_flock(pTHX_ int fd, int operation);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC I32	lop(pTHX_ I32 f, expectation x, char *s);
#endif
#if defined(PERL_IN_MG_C)
STATIC int	magic_methcall(pTHX_ SV *sv, MAGIC *mg, char *meth, I32 f, int n, SV *val);
#endif
#if defined(PERL_IN_MG_C)
STATIC int	magic_methpack(pTHX_ SV *sv, MAGIC *mg, char *meth);
#endif
#if defined(PERL_IN_UTIL_C)
STATIC SV*	mess_alloc(pTHX);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC void	missingterm(pTHX_ char *s);
#endif
#if defined(PERL_IN_OP_C)
STATIC OP*	modkids(pTHX_ OP *o, I32 type);
#endif
#if defined(PERL_IN_HV_C)
STATIC void	more_he(pTHX);
#endif
#if defined(PERL_IN_SV_C)
STATIC SV*	more_sv(pTHX);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	more_xiv(pTHX);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	more_xnv(pTHX);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	more_xpv(pTHX);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	more_xrv(pTHX);
#endif
#if defined(MYMALLOC) && defined(PERL_IN_MALLOC_C)
STATIC void	morecore(pTHX_ int bucket);
#endif
#if defined(PERL_IN_PP_C)
STATIC SV*	mul128(pTHX_ SV *sv, U8 m);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	my_exit_jump(pTHX) __attribute__((noreturn));
#endif
#if !defined(PURIFY) && defined(PERL_IN_SV_C)
STATIC void*	my_safemalloc(pTHX_ MEM_SIZE size);
#endif
#if defined(PERL_IN_OP_C)
STATIC OP*	newDEFSVOP(pTHX);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC SV*	new_constant(pTHX_ char *s, STRLEN len, char *key, SV *sv, SV *pv, char *type);
#endif
#if defined(PERL_IN_HV_C)
STATIC HE*	new_he(pTHX);
#endif
#if defined(PERL_IN_OP_C)
STATIC OP*	new_logop(pTHX_ I32 type, I32 flags, OP **firstp, OP **otherp);
#endif
#if defined(PERL_IN_SV_C)
STATIC XPVIV*	new_xiv(pTHX);
#endif
#if defined(PERL_IN_SV_C)
STATIC XPVNV*	new_xnv(pTHX);
#endif
#if defined(PERL_IN_SV_C)
STATIC XPV*	new_xpv(pTHX);
#endif
#if defined(PERL_IN_SV_C)
STATIC XRV*	new_xrv(pTHX);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC char*	nextchar(pTHX);
#endif
#if defined(PERL_IN_OP_C)
STATIC void	no_bareword_allowed(pTHX_ OP *o);
#endif
#if defined(PERL_IN_OP_C)
STATIC OP*	no_fh_allowed(pTHX_ OP *o);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC void	no_op(pTHX_ char *what, char *s);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	not_a_number(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	nuke_stacks(pTHX);
#endif
#if defined(PERL_IN_OP_C)
STATIC void	null(pTHX_ OP* o);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	open_script(pTHX_ char *, bool, SV *, int *fd);
#endif
#if defined(PERL_IN_OP_C)
STATIC PADOFFSET	pad_findlex(pTHX_ char* name, PADOFFSET newoff, U32 seq, CV* startcv, I32 cx_ix, I32 saweval, U32 flags);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void*	parse_body(pTHX_ va_list args);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC void	qsortsv(pTHX_ SV ** array, size_t num_elts, SVCOMPARE_t f);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC void	re_croak2(pTHX_ const char* pat1, const char* pat2, ...) __attribute__((noreturn));
#endif
#if defined(PERL_IN_PERL_C)
STATIC I32	read_e_script(pTHX_ int idx, SV *buf_sv, int maxlen);
#endif
#if defined(PERL_IN_PP_C)
STATIC SV*	refto(pTHX_ SV* sv);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC regnode*	reg(pTHX_ I32, I32 *);
#endif
#if defined(PURIFY) && defined(PERL_IN_SV_C)
STATIC void	reg_add(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC regnode*	reg_node(pTHX_ U8);
#endif
#if defined(PURIFY) && defined(PERL_IN_SV_C)
STATIC void	reg_remove(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC regnode*	reganode(pTHX_ U8, U32);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC regnode*	regatom(pTHX_ I32 *);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC regnode*	regbranch(pTHX_ I32 *, I32);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC void	regc(pTHX_ U8, char *);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC regnode*	regclass(pTHX);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC regnode*	regclassutf8(pTHX);
#endif
#if defined(PERL_IN_REGEXEC_C)
STATIC char*	regcp_set_to(pTHX_ I32 ss);
#endif
#if defined(PERL_IN_REGEXEC_C)
STATIC char*	regcppop(pTHX);
#endif
#if defined(PERL_IN_REGEXEC_C)
STATIC CHECKPOINT	regcppush(pTHX_ I32 parenfloor);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC I32	regcurly(pTHX_ char *);
#endif
#if defined(PERL_IN_REGEXEC_C)
STATIC U8*	reghop(pTHX_ U8 *pos, I32 off);
#endif
#if defined(PERL_IN_REGEXEC_C)
STATIC U8*	reghopmaybe(pTHX_ U8 *pos, I32 off);
#endif
#if defined(PERL_IN_REGEXEC_C)
STATIC bool	reginclass(pTHX_ char *p, I32 c);
#endif
#if defined(PERL_IN_REGEXEC_C)
STATIC bool	reginclassutf8(pTHX_ regnode *f, U8* p);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC void	reginsert(pTHX_ U8, regnode *);
#endif
#if defined(PERL_IN_REGEXEC_C)
STATIC I32	regmatch(pTHX_ regnode *prog);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC void	regoptail(pTHX_ regnode *, regnode *);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC regnode*	regpiece(pTHX_ I32 *);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC char*	regpposixcc(pTHX_ I32 value);
#endif
#if defined(PERL_IN_REGEXEC_C)
STATIC I32	regrepeat(pTHX_ regnode *p, I32 max);
#endif
#if defined(PERL_IN_REGEXEC_C)
STATIC I32	regrepeat_hard(pTHX_ regnode *p, I32 max, I32 *lp);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC void	regset(pTHX_ char *, I32);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC void	regtail(pTHX_ regnode *, regnode *);
#endif
#if defined(PERL_IN_REGEXEC_C)
STATIC I32	regtry(pTHX_ regexp *prog, char *startpos);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC void	reguni(pTHX_ UV, char *, I32*);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC char*	regwhite(pTHX_ char *, char *);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC void	restore_expect(pTHX_ void *e);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC void	restore_lex_expect(pTHX_ void *e);
#endif
#if defined(PERL_IN_MG_C)
STATIC void	restore_magic(pTHX_ void *p);
#endif
#if defined(PERL_IN_REGEXEC_C)
STATIC void	restore_pos(pTHX_ void *arg);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC void	restore_rsfp(pTHX_ void *f);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void*	run_body(pTHX_ va_list args);
#endif
#if defined(PERL_IN_HV_C)
STATIC HEK*	save_hek(pTHX_ const char *str, I32 len, U32 hash);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC void	save_lines(pTHX_ AV *array, SV *sv);
#endif
#if defined(PERL_IN_MG_C)
STATIC void	save_magic(pTHX_ I32 mgs_ix, SV *sv);
#endif
#if defined(PERL_IN_SCOPE_C)
STATIC SV*	save_scalar_at(pTHX_ SV **sptr);
#endif
#if defined(PERL_IN_OP_C)
STATIC bool	scalar_mod_type(pTHX_ OP *o, I32 type);
#endif
#if defined(PERL_IN_OP_C)
STATIC OP*	scalarboolean(pTHX_ OP *o);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC void	scan_commit(pTHX_ scan_data_t *data);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC char*	scan_const(pTHX_ char *start);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC char*	scan_formline(pTHX_ char *s);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC char*	scan_heredoc(pTHX_ char *s);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC char*	scan_ident(pTHX_ char *s, char *send, char *dest, STRLEN destlen, I32 ck_uni);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC char*	scan_inputsymbol(pTHX_ char *start);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC char*	scan_pat(pTHX_ char *start, I32 type);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC char*	scan_str(pTHX_ char *start);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC char*	scan_subst(pTHX_ char *start);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC char*	scan_trans(pTHX_ char *start);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC char*	scan_word(pTHX_ char *s, char *dest, STRLEN destlen, int allow_package, STRLEN *slp);
#endif
#if defined(PERL_IN_PP_C)
STATIC U32	seed(pTHX);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC void	set_csh(pTHX);
#endif
#if defined(PERL_IN_OP_C)
STATIC void	simplify_sort(pTHX_ OP *o);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC char*	skipspace(pTHX_ char *s);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC I32	sortcv(pTHX_ SV *a, SV *b);
#endif
#if defined(PERL_IN_REGCOMP_C)
STATIC I32	study_chunk(pTHX_ regnode **scanp, I32 *deltap, regnode *last, scan_data_t *data, U32 flags);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC I32	sublex_done(pTHX);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC I32	sublex_push(pTHX);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC I32	sublex_start(pTHX);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	sv_add_backref(pTHX_ SV *tsv, SV *sv);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	sv_del_backref(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC I32	sv_i_ncmp(pTHX_ SV *a, SV *b);
#endif
#if defined(PERL_IN_PP_CTL_C)
STATIC I32	sv_ncmp(pTHX_ SV *a, SV *b);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	sv_unglob(pTHX_ SV* sv);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC SV*	tokeq(pTHX_ SV *sv);
#endif
#if defined(PERL_IN_OP_C)
STATIC OP*	too_few_arguments(pTHX_ OP *o, char* name);
#endif
#if defined(PERL_IN_OP_C)
STATIC OP*	too_many_arguments(pTHX_ OP *o, char* name);
#endif
#if defined(CRIPPLED_CC) && defined(PERL_IN_TOKE_C)
STATIC int	uni(pTHX_ I32 f, char *s);
#endif
#if defined(USE_THREADS) && defined(PERL_IN_PP_HOT_C)
STATIC void	unset_cvowner(pTHX_ void *cvarg);
#endif
#if defined(PERL_IN_MG_C)
STATIC void	unwind_handler_stack(pTHX_ void *p);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	usage(pTHX_ char *);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC I32	utf16_textfilter(pTHX_ int idx, SV *sv, int maxlen);
#endif
#if defined(PERL_IN_TOKE_C)
STATIC I32	utf16rev_textfilter(pTHX_ int idx, SV *sv, int maxlen);
#endif
#if defined(PERL_IN_PERL_C)
STATIC void	validate_suid(pTHX_ char *, char*, int);
#endif
#if defined(PERL_IN_SV_C)
STATIC void	visit(pTHX_ SVFUNC_t f);
#endif
#if defined(WIN32) && defined(PERL_IN_TOKE_C)
STATIC I32	win32_textfilter(pTHX_ int idx, SV *sv, int maxlen);
#endif
#if defined(LEAKTEST) && defined(PERL_IN_UTIL_C)
STATIC void	xstat(pTHX_ int);
#endif
