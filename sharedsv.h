#ifdef USE_ITHREADS

typedef struct {
    SV                 *sv;             /* The actual SV */
    perl_mutex          mutex;          /* Our mutex */
    perl_cond           cond;           /* Our condition variable */
    perl_cond           user_cond;      /* For user-level conditions */
    IV                  locks;          /* Number of locks held */
    PerlInterpreter    *owner;          /* Who owns the lock? */
} shared_sv;

#define SHAREDSvGET(a)      (a->sv)
#define SHAREDSvLOCK(a)     Perl_sharedsv_lock(aTHX_ a)
#define SHAREDSvUNLOCK(a)   Perl_sharedsv_unlock(aTHX_ a)

#define SHAREDSvEDIT(a)     STMT_START {                                \
                                MUTEX_LOCK(&PL_sharedsv_space_mutex);   \
                                SHAREDSvLOCK((a));                      \
                                PERL_SET_CONTEXT(PL_sharedsv_space);    \
                            } STMT_END

#define SHAREDSvRELEASE(a)  STMT_START {                                \
                                PERL_SET_CONTEXT((a)->owner);           \
                                SHAREDSvUNLOCK((a));                    \
                                MUTEX_UNLOCK(&PL_sharedsv_space_mutex); \
                            } STMT_END

#endif /* USE_ITHREADS */
