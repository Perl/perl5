MODULE = XS::APItest                PACKAGE = XS::APItest::RWMacro

#if defined(USE_ITHREADS)

void
compile_macros()
    PREINIT:
        perl_RnW1_mutex_t m;
        perl_RnW1_mutex_t *pm = &m;
    CODE:
        PERL_RW_MUTEX_INIT(&m);
        PERL_WRITE_LOCK(&m);
        PERL_WRITE_UNLOCK(&m);
        PERL_READ_LOCK(&m);
        PERL_READ_UNLOCK(&m);
        PERL_RW_MUTEX_DESTROY(&m);
        PERL_RW_MUTEX_INIT(pm);
        PERL_WRITE_LOCK(pm);
        PERL_WRITE_UNLOCK(pm);
        PERL_READ_LOCK(pm);
        PERL_READ_UNLOCK(pm);
        PERL_RW_MUTEX_DESTROY(pm);

#endif
