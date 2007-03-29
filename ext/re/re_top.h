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
#define Perl_re_compile         my_re_compile
#define Perl_regfree_internal   my_regfree
#define Perl_re_intuit_string   my_re_intuit_string
#define Perl_regdupe_internal   my_regdupe
#define Perl_reg_numbered_buff_get  my_reg_numbered_buff_get
#define Perl_reg_named_buff_get  my_reg_named_buff_get
#define Perl_reg_qr_pkg  my_reg_qr_pkg

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
