/*    util.h
 *
 *    Copyright (C) 1991, 1992, 1993, 1999, 2001, 2002, 2003, 2004, 2005,
 *    2007, by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#ifdef VMS
#  define PERL_FILE_IS_ABSOLUTE(f) \
	(*(f) == '/'							\
	 || (strchr(f,':')						\
	     || ((*(f) == '[' || *(f) == '<')				\
		 && (isWORDCHAR((f)[1]) || strchr("$-_]>",(f)[1])))))

#else		/* !VMS */
#  if defined(WIN32) || defined(__CYGWIN__)
#    define PERL_FILE_IS_ABSOLUTE(f) \
	(*(f) == '/' || *(f) == '\\'		/* UNC/rooted path */	\
	 || ((f)[0] && (f)[1] == ':'))		/* drive name */
#  else		/* !WIN32 */
#  ifdef NETWARE
#    define PERL_FILE_IS_ABSOLUTE(f) \
	(((f)[0] && (f)[1] == ':')		/* drive name */	\
	 || ((f)[0] == '\\' && (f)[1] == '\\')	/* UNC path */	\
	 ||	((f)[3] == ':'))				/* volume name, currently only sys */
#  else		/* !NETWARE */
#    if defined( __KLIBC__)
#      define PERL_FILE_IS_ABSOLUTE(f) \
       (*(f) == '/' || *(f) == '\\'    \
        || ((f)[1] == ':' && (f)[2] == '/') || ((f)[1] == ':' && (f)[2] == '\\'))              /* drive name */
#    else                /* !__KLIBC__ */
#     if defined(DOSISH) || defined(__SYMBIAN32__)
#      define PERL_FILE_IS_ABSOLUTE(f) \
	(*(f) == '/'							\
	 || ((f)[0] && (f)[1] == ':'))		/* drive name */
#     else	/* NEITHER DOSISH NOR SYMBIANISH */
#      define PERL_FILE_IS_ABSOLUTE(f)	(*(f) == '/')
#     endif	/* DOSISH */
#    endif	/* NETWARE */
#   endif       /* __KLIBC__ */
#  endif	/* WIN32 */
#endif		/* VMS */

/*
=head1 Miscellaneous Functions

=for apidoc ibcmp

This is a synonym for (! foldEQ())

=for apidoc ibcmp_locale

This is a synonym for (! foldEQ_locale())

=cut
*/
#define ibcmp(s1, s2, len)         cBOOL(! foldEQ(s1, s2, len))
#define ibcmp_locale(s1, s2, len)  cBOOL(! foldEQ_locale(s1, s2, len))

/* outside the core, perl.h undefs HAS_QUAD if IV isn't 64-bit
   We can't swap this to HAS_QUAD, because the logic here affects the type of
   perl_drand48_t below, and that is visible outside of the core.  */
#if defined(U64TYPE) && !defined(USING_MSVC6)
/* use a faster implementation when quads are available,
 * but not with VC6 on Windows */
#    define PERL_DRAND48_QUAD
#endif

#ifdef PERL_DRAND48_QUAD

/* U64 is only defined under PERL_CORE, but this needs to be visible
 * elsewhere so the definition of PerlInterpreter is complete.
 */
typedef U64TYPE perl_drand48_t;

#else

struct PERL_DRAND48_T {
    U16 seed[3];
};

typedef struct PERL_DRAND48_T perl_drand48_t;

#endif

#define PL_RANDOM_STATE_TYPE perl_drand48_t

#define Perl_drand48_init(seed) (Perl_drand48_init_r(&PL_random_state, (seed)))
#define Perl_drand48() (Perl_drand48_r(&PL_random_state))

#ifdef USE_C_BACKTRACE

typedef struct {
    /* The number of frames returned. */
    UV frame_count;
    /* The total size of the Perl_c_backtrace, including this header,
     * the frames, and the name strings. */
    UV total_bytes;
} Perl_c_backtrace_header;

typedef struct {
    void*  addr;  /* the program counter at this frame */

    /* We could use Dl_info (as used by dladdr()) for many of these but
     * that would be naughty towards non-dlfcn systems (hi there, Win32). */

    void*  symbol_addr; /* symbol address (hint: try symbol_addr - addr) */
    void*  object_base_addr;   /* base address of the shared object */

    /* The offsets are from the beginning of the whole backtrace,
     * which makes the backtrace relocatable. */
    STRLEN object_name_offset; /* pathname of the shared object */
    STRLEN object_name_size;   /* length of the pathname */
    STRLEN symbol_name_offset; /* symbol name */
    STRLEN symbol_name_size;   /* length of the symbol name */
    STRLEN source_name_offset; /* source code file name */
    STRLEN source_name_size;   /* length of the source code file name */
    STRLEN source_line_number; /* source code line number */

    /* OS X notes: atos(1) (more recently, "xcrun atos"), but the C
     * API atos() uses is unknown (private "Symbolicator" framework,
     * might require Objective-C even if the API would be known).
     * Currently we open read pipe to "xcrun atos" and parse the
     * output - quite disgusting.  And that won't work if the
     * Developer Tools isn't installed. */

    /* FreeBSD notes: execinfo.h exists, but probably would need also
     * the library -lexecinfo.  BFD exists if the pkg devel/binutils
     * has been installed, but there seems to be a known problem that
     * the "bfd.h" getting installed refers to "ansidecl.h", which
     * doesn't get installed. */

    /* Win32 notes: as moral equivalents of backtrace() + dladdr(),
     * one could possibly first use GetCurrentProcess() +
     * SymInitialize(), and then CaptureStackBackTrace() +
     * SymFromAddr(). */

    /* Note that using the compiler optimizer easily leads into much
     * of this information, like the symbol names (think inlining),
     * and source code locations getting lost or confused.  In many
     * cases keeping the debug information (-g) is necessary.
     *
     * Note that for example with gcc you can do both -O and -g.
     *
     * Note, however, that on some platforms (e.g. OSX + clang (cc))
     * backtrace() + dladdr() works fine without -g. */

    /* For example: the mere presence of <bfd.h> is no guarantee: e.g.
     * OS X has that, but BFD does not seem to work on the OSX executables.
     *
     * Another niceness would be to able to see something about
     * the function arguments, however gdb/lldb manage to do that. */
} Perl_c_backtrace_frame;

typedef struct {
    Perl_c_backtrace_header header;
    Perl_c_backtrace_frame  frame_info[1];
    /* After the header come:
     * (1) header.frame_count frames
     * (2) frame_count times the \0-terminated strings (object_name
     * and so forth).  The frames contain the pointers to the starts
     * of these strings, and the lengths of these strings. */
} Perl_c_backtrace;

#define Perl_free_c_backtrace(bt) Safefree(bt)

#endif /* USE_C_BACKTRACE */

/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 et:
 */
