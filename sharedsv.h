
#ifdef USE_ITHREADS

typedef struct {
    SV*              sv;    /* The actual data */
    perl_mutex       mutex; /* Our mutex */
    perl_cond        cond;  /* Our condition variable */
    IV               locks; /* Number of locks held */
    PerlInterpreter* owner; /* who owns the lock */
} shared_sv;

extern PerlInterpreter* sharedsv_space;

void Perl_sharedsv_unlock_scope(pTHX_ shared_sv* ssv);
void Perl_sharedsv_unlock(pTHX_ shared_sv* ssv);
void Perl_sharedsv_lock(pTHX_ shared_sv* ssv);
void Perl_sharedsv_init(pTHX);
shared_sv* Perl_sharedsv_new(pTHX);
shared_sv* Perl_sharedsv_find(pTHX_ SV* sv);
void Perl_sharedsv_thrcnt_inc(pTHX_ shared_sv* ssv);
void Perl_sharedsv_thrcnt_dec(pTHX_ shared_sv* ssv);


#define SHAREDSvGET(a)     (a->sv)
#define SHAREDSvEDIT(a)    PERL_SET_CONTEXT(sharedsv_space)
#define SHAREDSvRELEASE(a) PERL_SET_CONTEXT(my_perl)
#define SHAREDSvLOCK(a)    Perl_sharedsv_lock(aTHX_ a)
#define SHAREDSvUNLOCK(a)  Perl_sharedsv_unlock(aTHX_ a)

#endif /* USE_ITHREADS */

