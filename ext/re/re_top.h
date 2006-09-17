/* need to replace pregcomp et al, so enable that */
#ifndef PERL_IN_XSUB_RE
#  define PERL_IN_XSUB_RE
#endif
/* need access to debugger hooks */
#if defined(PERL_EXT_RE_DEBUG) && !defined(DEBUGGING)
#  define DEBUGGING
#endif

/* We *really* need to overwrite these symbols: */
#define Perl_regexec_flags      my_regexec
#define Perl_regdump            my_regdump
#define Perl_regprop            my_regprop
#define Perl_re_intuit_start    my_re_intuit_start
#define Perl_pregcomp           my_regcomp
#define Perl_pregfree           my_regfree
#define Perl_re_intuit_string   my_re_intuit_string
#define Perl_regdupe            my_regdupe

#define PERL_NO_GET_CONTEXT

/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: t
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 noet:
 */
