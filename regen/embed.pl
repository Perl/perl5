#!/usr/bin/perl -w

# Regenerate (overwriting only if changed):
#
#    embed.h
#    embedvar.h
#    proto.h
#
# from information stored in
#
#    embed.fnc
#    intrpvar.h
#    perlvars.h
#    regen/opcodes
#    All top level .c files in MANIFEST
#    Most top level .h files in MANIFEST, exception list %skip_files below
#    Some pod files, listed in @pod_list below
#
# Accepts the standard regen_lib -q and -v args.
#
# This script is normally invoked from regen.pl.

# See database of global and static function prototypes in embed.fnc
# This is used to generate prototype headers under various configurations,
# export symbols lists for different platforms, and macros to provide an
# implicit interpreter context argument.
#
# We strive to not pollute the namespace of XS modules.  To that end, embed.h
# (in cooperation with perl.h) keeps all macro names out of that namespace
# that this program thinks shouldn't be in it.  The way that works is that
# perl.h #includes embed.h twice.  The first time is to #define everything
# needed.  And the second time, to #undef those elements that aren't needed
# for the #including file.  For the perl core, everything is retained; for
# perl extensions, much is retained; for the rest, only expected things are
# retained.  The #undef'ing is done after any inline functions are processed,
# so they always have access to everything.

require 5.004;  # keep this compatible, an old perl is all we may have before
                # we build the new one

use strict;

BEGIN {
    # Get function prototypes
    require './regen/regen_lib.pl';
    require './regen/embed_lib.pl';
}

# This program has historically generated compatibility macros for a few
# functions of the form Perl_FOO(pTHX_ ...).  Those macros would be named
# FOO(...), and would expand outside the core to Perl_FOO_nocontext(...)
# instead of the expected value.  This was done so XS code that didn't do a
# PERL_GET_CONTEXT would continue to work unchanged after threading was
# introduced.  Any new API functions that came along would require an aTHX_
# parameter; this was just to avoid breaking existing source.  Hence no new
# functions need be added to the list of such macros.  This is the list.
# All have varargs.
#
# N.B. If you change this list, update the copy in autodoc.pl.  This is likely
# to never happen, so not worth coding automatic synchronization.
my @have_compatibility_macros = qw(
                                    deb
                                    form
                                    load_module
                                    mess
                                    newSVpvf
                                    sv_catpvf
                                    sv_catpvf_mg
                                    sv_setpvf
                                    sv_setpvf_mg
                                    warn
                                    warner
                                  );
my %has_compat_macro;
$has_compat_macro{$_} = 1 for @have_compatibility_macros;
my %perl_compats;   # Have 'perl_' prefix

# This program inspects various top-level header files, except those on this
# list.  These are all machine-generated, or not relevant for our purposes.
my %skip_files;
$skip_files{$_} = 1 for qw(
                            charclass_invlists.inc
                            embed.h
                            embedvar.h
                            fakesdio.h
                            nostdio.h
                            perl_langinfo.h
                            perlio.h
                            proto.h
                            XSUB.h
                          );

# Items that are marked as being in the API are, by definition, not namespace
# pollutants.  To find those, this program looks for API declarations.  These
# are in embed.fnc, any top-level dot c file, and certain pod files.  In order
# to save a bit of run time, this static list comprises the pod files known to
# have such defintions.  It is not expected this will change often.
my @pod_list = qw(
                   INSTALL
                   pod/perlguts.pod
                   pod/perlinterp.pod
                   pod/perlapio.pod
                   pod/perlhacktips.pod
                   pod/perlcall.pod
                   pod/perlreguts.pod
                   pod/perlmroapi.pod
                   pod/perlembed.pod
                   dist/ExtUtils-ParseXS/lib/perlxs.pod
                   pod/perliol.pod
                   pod/perlreapi.pod
                 );

# A regular expression that matches names that are externally visible, but
# Perl reserves for itself.  Generally, we want things to be delimitted on
# both sides to show it isn't part of a larger word such as 'hyperlink',
# 'perlustrate', or 'properly'.  Underscores delimit besides the typical ^ or
# \b.  All caps PERL has looser rules to accommodate the many existing symbols
# where everything is jammed together, and the less likelihood that something
# with all caps is innocently referring to something unrelated to Perl.
my $names_reserved_for_perl_use_re =
                         qr/  ^ (  PL_ \w+ \b
                                 | perl_        # The underscore delimits
                                 | Perl [_A-Z]  # Uppercase delimits here too
                                 | PERL [A-Z]+ [[:alpha:]] ( \b | _ )
                                )

                              # The \d is for PERL5, for example
                            | ( _ | \b )  PERL ( _ | \b | \d+ )

                              # This is for obsolete and deprecated uses
                            | ( _ | \b ) CPERL (arg | scope) ( _ | \b )

                            | _ (?: pl | PL) _ \b
                          /x;

# This program looks at C preprocessor conditional expressions.  It turns out
# that many of those it cares about can be evaluated by knowing some
# conventions used in our source.  This hash allows for information beyond
# those conventions to be known.  Each key is a file, and its value is a
# sub-hash.  Each key in that is a condition name which occurs in the source
# as '#ifdef foo' or some variation on that. And the value of that key is 0 if
# 'foo' is to be considered undefined while parsing the file; or 1 if the
# symbol is to be considered to be defined.  Things to put in here might be to
# set to 0 file-scope symbols that are only defined during development, such
# as ones that turn on a special debugging mode.
my %per_file_definitions = (
        'perl.h'             => { 'H_PERL' => 0 },
);

# This is a list of symbols that are:
#   1) not documented to be available for modules to use,
#   2) not resolved as needed to be visible to any module (and that we don't
#      plan to document any time soon),
#   3) but are nevertheless currently not kept by embed.h from being visible
#      to the world.
#
# Strive to make this list empty.
#
# Symbols in class 2) above should instead be placed in
# @undocumented_always_visible.
#
# The list does not include symbols that we have documented as being reserved
# for perl's use, namely those that match the pattern just above.
# There are two parts of the list; the second part contains the symbols which
# have a trailing underscore indicating the intent for this symbol to not be
# directly usable by XS code.  The first part are those symbols without a
# trailing underscore.
#
# For all modules that aren't deliberately using particular names, all the
# other symbols on it are namespace pollutants.
my @unresolved_visibility_overrides = qw(
    _
    ABORT
    ABS_IV_MIN
    ALIGNED_TYPE
    ALIGNED_TYPE_NAME
    ALLOC_THREAD_KEY
    ALL_PARENS_COUNTED
    ALWAYS_WARN_SUPER
    AMG_CALLun
    AMGfallNEVER
    AMGfallNO
    AMGfallYES
    AMGf_numarg
    AMGf_numeric
    AMGf_want_list
    AMG_id2name
    AMG_id2namelen
    AMT_AMAGIC
    AMT_AMAGIC_off
    AMT_AMAGIC_on
    AMTf_AMAGIC
    ANGSTROM_SIGN
    ARABIC_DECIMAL_SEPARATOR_UTF8
    ARABIC_DECIMAL_SEPARATOR_UTF8_FIRST_BYTE
    ARABIC_DECIMAL_SEPARATOR_UTF8_FIRST_BYTE_s
    ARABIC_DECIMAL_SEPARATOR_UTF8_TAIL
    ARGTARG
    ASCII_FOLD_RESTRICTED
    ASCII_MORE_RESTRICT_PAT_MODS
    ASCII_PLATFORM_UTF8_MAXBYTES
    ASCII_RESTRICTED
    ASCII_RESTRICT_PAT_MOD
    ASCII_RESTRICT_PAT_MODS
    ASCII_TO_NATIVE
    ASCTIME_LOCK
    ASCTIME_UNLOCK
    ASSERT_CURPAD_ACTIVE
    ASSERT_CURPAD_LEGAL
    ASSERT_IS_LITERAL
    ASSERT_IS_PTR
    assert_not_glob
    ASSERT_NOT_PTR
    assert_not_ROK
    aTHXa
    aTHXo
    aTHXx
    AT_LEAST_ASCII_RESTRICTED
    AT_LEAST_UNI_SEMANTICS
    Atoul
    AvARYLEN
    AvMAX
    AvREAL
    AvREALISH
    AvREAL_off
    AvREAL_on
    AvREAL_only
    AvREIFY
    AvREIFY_off
    AvREIFY_on
    AvREIFY_only
    av_tindex_skip_len_mg
    av_top_index_skip_len_mg
    BADVERSION
    BASEOP
    BhkENTRY
    BHKf_bhk_eval
    BHKf_bhk_post_end
    BHKf_bhk_pre_end
    BHKf_bhk_start
    BhkFLAGS
    BIT_BUCKET
    BIT_DIGITS
    blk_eval
    blk_format
    blk_gimme
    blk_givwhen
    blk_loop
    blk_oldcop
    blk_oldmarksp
    blk_oldpm
    blk_oldsaveix
    blk_oldscopesp
    blk_oldsp
    blk_old_tmpsfloor
    blk_sub
    blk_u16
    BmFLAGS
    BmPREVIOUS
    BmRARE
    BmUSEFUL
    BOM_UTF8_FIRST_BYTE
    BOM_UTF8_TAIL
    BSD_GETPGRP
    BSDish
    BSD_SETPGRP
    BYTEORDER
    CALL_BLOCK_HOOKS
    CALL_FPTR
    CALLREGCOMP
    CALLREGCOMP_ENG
    CALLREGDUPE
    CALLREGDUPE_PVT
    CALLREGEXEC
    CALLREGFREE
    CALLREGFREE_PVT
    CALLREG_INTUIT_START
    CALLREG_INTUIT_STRING
    CALLREG_NAMED_BUFF_ALL
    CALLREG_NAMED_BUFF_CLEAR
    CALLREG_NAMED_BUFF_COUNT
    CALLREG_NAMED_BUFF_DELETE
    CALLREG_NAMED_BUFF_EXISTS
    CALLREG_NAMED_BUFF_FETCH
    CALLREG_NAMED_BUFF_FIRSTKEY
    CALLREG_NAMED_BUFF_NEXTKEY
    CALLREG_NAMED_BUFF_SCALAR
    CALLREG_NAMED_BUFF_STORE
    CALLREG_NUMBUF_FETCH
    CALLREG_NUMBUF_LENGTH
    CALLREG_NUMBUF_STORE
    CALLREG_PACKAGE
    CALLRUNOPS
    CAN64BITHASH
    CAN_COW_FLAGS
    CAN_COW_MASK
    CAN_PROTOTYPE
    CASE_STD_PMMOD_FLAGS_PARSE_SET
    CATCH_GET
    CATCH_SET
    cBINOP
    cBINOPo
    cBINOPx
    cCOP
    cCOPo
    cCOPx
    C_FAC_POSIX
    cGVOP_gv
    cGVOPo_gv
    cGVOPx_gv
    CHANGE_MULTICALL_FLAGS
    CHARSET_PAT_MODS
    CHECK_MALLOC_TAINT
    CHECK_MALLOC_TOO_LATE_FOR
    child_offset_bits
    CHR_SVLEN
    ckDEAD
    ckWARN2_non_literal_string
    ckWARN2reg
    ckWARN2reg_d
    ckWARN3reg
    ckWARN4reg
    ckWARNdep
    ckWARNexperimental
    ckWARNexperimental_with_arg
    ckWARNreg
    ckWARNregdep
    CLANG_DIAG_IGNORE
    CLANG_DIAG_IGNORE_DECL
    CLANG_DIAG_IGNORE_STMT
    CLANG_DIAG_PRAGMA
    CLANG_DIAG_RESTORE
    CLANG_DIAG_RESTORE_DECL
    CLANG_DIAG_RESTORE_STMT
    classnum_to_namedclass
    CLEAR_ARGARRAY
    CLEAR_OPTSTART
    cLISTOP
    cLISTOPo
    cLISTOPx
    cLOGOP
    cLOGOPo
    cLOGOPx
    CLONEf_JOIN_IN
    cLOOP
    cLOOPo
    cLOOPx
    CLUMP_2IV
    CLUMP_2UV
    cMETHOP
    cMETHOP_meth
    cMETHOPo
    cMETHOPo_meth
    cMETHOPo_rclass
    cMETHOP_rclass
    cMETHOPx
    cMETHOPx_meth
    cMETHOPx_rclass
    COMBINING_DOT_ABOVE_UTF8
    COMBINING_GRAVE_ACCENT_UTF8
    COMBINING_GREEK_YPOGEGRAMMENI_UTF8
    COND_BROADCAST
    COND_DESTROY
    COND_INIT
    COND_SIGNAL
    COND_WAIT
    CONTINUE_PAT_MOD
    COP_FEATURE_SIZE
    CopFEATURES_setfrom
    CopFILEAVx
    CopFILE_copy_x
    CopFILE_debug
    CopFILE_free_x
    CopFILE_setn_x
    CopFILE_set_x
    COPHH_EXISTS
    CopHINTHASH_get
    CopHINTHASH_set
    CopHINTS_get
    CopHINTS_set
    CopLABEL_alloc
    CopLINE_dec
    CopLINE_inc
    CopLINE_set
    COP_SEQMAX_INC
    COP_SEQ_RANGE_HIGH
    COP_SEQ_RANGE_LOW
    CopSTASH_ne
    copy_length
    CowREFCNT
    cPADOP
    cPADOPo
    cPADOPx
    cPMOP
    cPMOPo
    cPMOPx
    cPVOP
    cPVOPo
    cPVOPx
    CR_NATIVE
    cSVOP
    cSVOPo
    cSVOPo_sv
    cSVOP_sv
    cSVOPx
    cSVOPx_sv
    cSVOPx_svp
    CTIME_LOCK
    CTIME_UNLOCK
    Ctl
    CTYPE256
    cUNOP
    cUNOP_AUX
    cUNOP_AUXo
    cUNOP_AUXx
    cUNOPo
    cUNOPx
    CvANON
    CvANONCONST
    CvANONCONST_off
    CvANONCONST_on
    CvANON_off
    CvANON_on
    CvAUTOLOAD
    CvAUTOLOAD_off
    CvAUTOLOAD_on
    cv_ckproto
    CvCLONE
    CvCLONED
    CvCLONED_off
    CvCLONED_on
    CvCLONE_off
    CvCLONE_on
    CvCONST
    CvCONST_off
    CvCONST_on
    CvCVGV_RC
    CvCVGV_RC_off
    CvCVGV_RC_on
    CvDEPTHunsafe
    CvDYNFILE
    CvDYNFILE_off
    CvDYNFILE_on
    CvEVAL
    CvEVAL_COMPILED
    CvEVAL_COMPILED_off
    CvEVAL_COMPILED_on
    CvEVAL_off
    CvEVAL_on
    CVf_ANON
    CVf_ANONCONST
    CVf_AUTOLOAD
    CVf_BUILTIN_ATTRS
    CVf_CLONE
    CVf_CLONED
    CVf_CONST
    CVf_CVGV_RC
    CVf_DYNFILE
    CVf_EVAL_COMPILED
    CVf_HASEVAL
    CvFILE
    CvFILEGV
    CvFILE_set_from_cop
    CVf_IsMETHOD
    CVf_ISXSUB
    CvFLAGS
    CVf_LEXICAL
    CVf_LVALUE
    CVf_METHOD
    CVf_NAMED
    CVf_NODEBUG
    CVf_NOWARN_AMBIGUOUS
    CVf_REFCOUNTED_ANYSV
    CVf_SIGNATURE
    CVf_UNIQUE
    CVf_WEAKOUTSIDE
    CVf_XS_RCSTACK
    CvGvNAME_HEK
    CvGV_set
    CvHASEVAL
    CvHASEVAL_off
    CvHASEVAL_on
    CvHASGV
    CvHSCXT
    CvIsMETHOD
    CvIsMETHOD_off
    CvIsMETHOD_on
    CvISXSUB
    CvISXSUB_off
    CvISXSUB_on
    CvLEXICAL
    CvLEXICAL_off
    CvLEXICAL_on
    CvLVALUE
    CvLVALUE_off
    CvLVALUE_on
    CvMETHOD
    CvMETHOD_off
    CvMETHOD_on
    CvNAMED
    CvNAMED_off
    CvNAMED_on
    CvNAME_HEK_set
    CvNODEBUG
    CvNODEBUG_off
    CvNODEBUG_on
    CvNOWARN_AMBIGUOUS
    CvNOWARN_AMBIGUOUS_off
    CvNOWARN_AMBIGUOUS_on
    CvOUTSIDE
    CvOUTSIDE_SEQ
    CvPADLIST_set
    CvPROTO
    CvPROTOLEN
    CvREFCOUNTED_ANYSV
    CvREFCOUNTED_ANYSV_off
    CvREFCOUNTED_ANYSV_on
    CvSIGNATURE
    CvSIGNATURE_off
    CvSIGNATURE_on
    CvSPECIAL
    CvSPECIAL_off
    CvSPECIAL_on
    CvSTASH_set
    CvUNIQUE
    CvUNIQUE_off
    CvUNIQUE_on
    CvWEAKOUTSIDE
    CvWEAKOUTSIDE_off
    CvWEAKOUTSIDE_on
    CvXS_RCSTACK
    CvXS_RCSTACK_off
    CvXS_RCSTACK_on
    CvXSUB
    CvXSUBANY
    CX_CURPAD_SAVE
    CX_CURPAD_SV
    CX_DEBUG
    CxEVALBLOCK
    CxEVAL_TXT_REFCNTED
    CxFOREACH
    CxHASARGS
    CxITERVAR
    CxLABEL
    CxLABEL_len
    CxLABEL_len_flags
    CxLVAL
    CxMULTICALL
    CxOLD_IN_EVAL
    CxOLD_OP_TYPE
    CxONCE
    CxPADLOOP
    CXp_EVALBLOCK
    CXp_FINALLY
    CXp_FOR_DEF
    CXp_FOR_GV
    CXp_FOR_LVREF
    CXp_FOR_PAD
    CXp_HASARGS
    CXp_MULTICALL
    CXp_ONCE
    CX_POP_SAVEARRAY
    CXp_REAL
    CXp_SUB_RE
    CXp_SUB_RE_FAKE
    CXp_TRY
    CXp_TRYBLOCK
    CX_PUSHSUB_GET_LVALUE_MASK
    CxREALEVAL
    cxstack_max
    CXt_DEFER
    CxTRY
    CxTRYBLOCK
    CxTYPE
    CxTYPE_is_LOOP
    CXTYPEMASK
    dATARGET
    DBVARMG_COUNT
    DBVARMG_SIGNAL
    DBVARMG_SINGLE
    DBVARMG_TRACE
    DEBUG_DB_RECURSE_FLAG
    DEBUG_MASK
    DEBUG_PEEP
    DEBUG_POST_STMTS
    DEBUG_PRE_STMTS
    DEBUG_RExC_seen
    DEBUG_SBOX32_HASH
    DEBUG_SCOPE
    DEBUG_SHOW_STUDY_FLAG
    DEBUG_STUDYDATA
    DEBUG_TOP_FLAG
    DEBUG_ZAPHOD32_HASH
    DEFAULT_PAT_MOD
    DEFERRED_COULD_BE_OFFICIAL_MARKERc
    DEFERRED_COULD_BE_OFFICIAL_MARKERs
    DEFERRED_USER_DEFINED_INDEX
    del_body_by_type
    DEL_NATIVE
    DEPENDS_PAT_MOD
    DEPENDS_PAT_MODS
    DEPENDS_SEMANTICS
    DETACH
    DIE
    DISABLE_LC_NUMERIC_CHANGES
    dJMPENV
    djSP
    DM_ARRAY_ISA
    DM_DELAY
    DM_EGID
    DM_EUID
    DM_GID
    DM_RGID
    DM_RUID
    DM_UID
    dMY_CXT_INTERP
    do_exec
    DOSISH
    DOUBLE_BIG_ENDIAN
    DOUBLE_HAS_INF
    DOUBLE_HAS_NAN
    DOUBLE_IS_IEEE_FORMAT
    DOUBLE_IS_VAX_FLOAT
    DOUBLE_LITTLE_ENDIAN
    DOUBLE_MIX_ENDIAN
    DOUBLE_VAX_ENDIAN
    dPOPiv
    dPOPnv
    dPOPnv_nomg
    dPOPPOPiirl
    dPOPPOPnnrl
    dPOPPOPssrl
    dPOPss
    dPOPTOPiirl
    dPOPTOPiirl_nomg
    dPOPTOPiirl_ul_nomg
    dPOPTOPnnrl
    dPOPTOPnnrl_nomg
    dPOPTOPssrl
    dPOPuv
    dPOPXiirl
    dPOPXiirl_ul_nomg
    dPOPXnnrl
    dPOPXssrl
    DPTR2FPTR
    dSAVEDERRNO
    dSAVE_ERRNO
    dSS_ADD
    dTARG
    dTARGETSTACKED
    dTHX_DEBUGGING
    dTHXo
    dTHXs
    dTHXx
    dTOPiv
    dTOPnv
    dTOPss
    dTOPuv
    DUMPUNTIL
    DUP_WARNINGS
    dXSUB_SYS
    eC
    eI
    EIGHT_BIT_UTF8_TO_NATIVE
    EMBEDMYMALLOC
    ENDGRENT_R_HAS_FPTR
    ENDPWENT_R_HAS_FPTR
    ENV_INIT
    ENV_LOCK
    ENV_READ_LOCK
    ENV_READ_UNLOCK
    ENVr_LOCALEr_LOCK
    ENVr_LOCALEr_UNLOCK
    ENV_TERM
    ENV_UNLOCK
    ESC_NATIVE
    EVAL_INEVAL
    EVAL_INREQUIRE
    EVAL_KEEPERR
    EVAL_NULL
    EVAL_RE_REPARSING
    EVAL_WARNONLY
    EXEC_ARGV_CAST
    EXEC_PAT_MOD
    EXEC_PAT_MODS
    EXPECT
    EXPERIMENTAL_INPLACESCAN
    EXTEND_HWM_SET
    EXTEND_MORTAL
    EXTEND_SKIP
    EXT_MGVTBL
    EXT_PAT_MODS
    FAIL
    FAIL2
    FAIL3
    FAKE_BIT_BUCKET
    FAKE_DEFAULT_SIGNAL_HANDLERS
    FAKE_PERSISTENT_SIGNAL_HANDLERS
    FALSE
    F_atan2_amg
    FBMcf_TAIL
    FBMcf_TAIL_DOLLAR
    FBMcf_TAIL_DOLLARM
    FBMcf_TAIL_z
    FBMcf_TAIL_Z
    FBMrf_MULTILINE
    F_cos_amg
    F_exp_amg
    FF_0DECIMAL
    FF_BLANK
    FF_CHECKCHOP
    FF_CHECKNL
    FF_CHOP
    FF_DECIMAL
    FF_END
    FF_FETCH
    FF_HALFSPACE
    FF_ITEM
    FF_LINEGLOB
    FF_LINEMARK
    FF_LINESNGL
    FF_LITERAL
    Fflush
    FF_MORE
    FF_NEWLINE
    FF_SKIP
    FF_SPACE
    FILTER_DATA
    FILTER_ISREADER
    FILTER_READ
    FIT_ARENA
    FIT_ARENA0
    FIT_ARENAn
    FITS_IN_8_BITS
    F_log_amg
    FmLINES
    FOLD
    FOLD_FLAGS_FULL
    FOLD_FLAGS_LOCALE
    FOLD_FLAGS_NOMIX_ASCII
    F_pow_amg
    FP_PINF
    FP_QNAN
    FPTR2DPTR
    free_and_set_cop_warnings
    free_c_backtrace
    FreeOp
    FREE_THREAD_KEY
    FSEEKSIZE
    F_sin_amg
    F_sqrt_amg
    Fstat
    FULL_TRIE_STUDY
    fwrite1
    G_ARRAY
    GCC_DIAG_IGNORE
    GCC_DIAG_IGNORE_DECL
    GCC_DIAG_IGNORE_STMT
    GCC_DIAG_PRAGMA
    GCC_DIAG_RESTORE
    GCC_DIAG_RESTORE_DECL
    GCC_DIAG_RESTORE_STMT
    GETATARGET
    GETENV_LOCK
    GETENV_UNLOCK
    get_extended_os_errno
    GETGRENT_R_HAS_BUFFER
    GETGRENT_R_HAS_FPTR
    GETGRENT_R_HAS_PTR
    GETGRGID_R_HAS_BUFFER
    GETGRGID_R_HAS_PTR
    GETGRNAM_R_HAS_BUFFER
    GETGRNAM_R_HAS_PTR
    GETHOSTBYADDR_LOCK
    GETHOSTBYADDR_R_HAS_BUFFER
    GETHOSTBYADDR_R_HAS_ERRNO
    GETHOSTBYADDR_R_HAS_PTR
    GETHOSTBYADDR_UNLOCK
    GETHOSTBYNAME_LOCK
    GETHOSTBYNAME_R_HAS_BUFFER
    GETHOSTBYNAME_R_HAS_ERRNO
    GETHOSTBYNAME_R_HAS_PTR
    GETHOSTBYNAME_UNLOCK
    GETHOSTENT_R_HAS_BUFFER
    GETHOSTENT_R_HAS_ERRNO
    GETHOSTENT_R_HAS_PTR
    GETNETBYADDR_LOCK
    GETNETBYADDR_R_HAS_BUFFER
    GETNETBYADDR_R_HAS_ERRNO
    GETNETBYADDR_R_HAS_PTR
    GETNETBYADDR_UNLOCK
    GETNETBYNAME_LOCK
    GETNETBYNAME_R_HAS_BUFFER
    GETNETBYNAME_R_HAS_ERRNO
    GETNETBYNAME_R_HAS_PTR
    GETNETBYNAME_UNLOCK
    GETNETENT_R_HAS_BUFFER
    GETNETENT_R_HAS_ERRNO
    GETNETENT_R_HAS_PTR
    GETPROTOBYNAME_LOCK
    GETPROTOBYNAME_R_HAS_BUFFER
    GETPROTOBYNAME_R_HAS_PTR
    GETPROTOBYNAME_UNLOCK
    GETPROTOBYNUMBER_LOCK
    GETPROTOBYNUMBER_R_HAS_BUFFER
    GETPROTOBYNUMBER_R_HAS_PTR
    GETPROTOBYNUMBER_UNLOCK
    GETPROTOENT_LOCK
    GETPROTOENT_R_HAS_BUFFER
    GETPROTOENT_R_HAS_PTR
    GETPROTOENT_UNLOCK
    GETPWENT_R_HAS_BUFFER
    GETPWENT_R_HAS_FPTR
    GETPWENT_R_HAS_PTR
    GETPWNAM_LOCK
    GETPWNAM_R_HAS_BUFFER
    GETPWNAM_R_HAS_PTR
    GETPWNAM_UNLOCK
    GETPWUID_LOCK
    GETPWUID_R_HAS_PTR
    GETPWUID_UNLOCK
    GETSERVBYNAME_LOCK
    GETSERVBYNAME_R_HAS_BUFFER
    GETSERVBYNAME_R_HAS_PTR
    GETSERVBYNAME_UNLOCK
    GETSERVBYPORT_LOCK
    GETSERVBYPORT_R_HAS_BUFFER
    GETSERVBYPORT_R_HAS_PTR
    GETSERVBYPORT_UNLOCK
    GETSERVENT_LOCK
    GETSERVENT_R_HAS_BUFFER
    GETSERVENT_R_HAS_PTR
    GETSERVENT_UNLOCK
    GETSPNAM_LOCK
    GETSPNAM_R_HAS_BUFFER
    GETSPNAM_R_HAS_PTR
    GETSPNAM_UNLOCK
    GETTARGET
    GETTARGETSTACKED
    G_FAKINGEVAL
    GLOBAL_PAT_MOD
    GMTIME_LOCK
    GMTIME_UNLOCK
    G_NODEBUG
    GREEK_CAPITAL_LETTER_MU
    GREEK_SMALL_LETTER_MU
    G_RE_REPARSING
    G_UNDEF_FILL
    Gv_AMG
    GvASSUMECV
    GvASSUMECV_off
    GvASSUMECV_on
    GV_AUTOLOAD
    GvAVn
    GV_CROAK
    GvCVGEN
    GvCV_set
    GvCVu
    GvEGV
    GvEGVx
    GvENAME
    GvENAME_HEK
    GvENAMELEN
    GvENAMEUTF8
    GvESTASH
    GVf_ASSUMECV
    gv_fetchmethod_flags
    GvFILE
    GvFILEGV
    GvFILE_HEK
    GvFILEx
    GVf_IMPORTED
    GVf_IMPORTED_AV
    GVf_IMPORTED_CV
    GVf_IMPORTED_HV
    GVf_IMPORTED_SV
    GVf_INTRO
    GvFLAGS
    GVf_MULTI
    GVF_NOADD
    GVf_ONCE_FATAL
    GvFORM
    GVf_RESERVED
    GvGP
    GvGPFLAGS
    GvGP_set
    GvHVn
    GvIMPORTED
    GvIMPORTED_AV
    GvIMPORTED_AV_off
    GvIMPORTED_AV_on
    GvIMPORTED_CV
    GvIMPORTED_CV_off
    GvIMPORTED_CV_on
    GvIMPORTED_HV
    GvIMPORTED_HV_off
    GvIMPORTED_HV_on
    GvIMPORTED_off
    GvIMPORTED_on
    GvIMPORTED_SV
    GvIMPORTED_SV_off
    GvIMPORTED_SV_on
    GvIN_PAD
    GvIN_PAD_off
    GvIN_PAD_on
    GvINTRO
    GvINTRO_off
    GvINTRO_on
    GvIO
    GvIOn
    GvIOp
    GvLINE
    gv_method_changed
    GvMULTI
    GvMULTI_off
    GvMULTI_on
    GvNAME
    GvNAME_get
    GvNAME_HEK
    GvNAMELEN
    GvNAMELEN_get
    GvNAMEUTF8
    GV_NOADD_MASK
    GvONCE_FATAL
    GvONCE_FATAL_off
    GvONCE_FATAL_on
    GvREFCNT
    GvSTASH
    GvXPVGV
    G_WANT
    G_WARN_ALL_MASK
    G_WARN_ALL_OFF
    G_WARN_ALL_ON
    G_WARN_OFF
    G_WARN_ON
    G_WARN_ONCE
    gwENVr_LOCALEr_LOCK
    gwENVr_LOCALEr_UNLOCK
    gwLOCALE_LOCK
    gwLOCALEr_LOCK
    gwLOCALEr_UNLOCK
    gwLOCALE_UNLOCK
    G_WRITING_TO_STDERR
    HADNV
    HASARENA
    HASATTRIBUTE_ALWAYS_INLINE
    HASATTRIBUTE_DEPRECATED
    HASATTRIBUTE_FORMAT
    HASATTRIBUTE_MALLOC
    HASATTRIBUTE_NONNULL
    HASATTRIBUTE_NORETURN
    HASATTRIBUTE_PURE
    HASATTRIBUTE_UNUSED
    HASATTRIBUTE_VISIBILITY
    HASATTRIBUTE_WARN_UNUSED_RESULT
    HAS_BUILTIN_UNREACHABLE
    HAS_C99
    HAS_CHOWN
    HAS_EXTENDED_OS_ERRNO
    HAS_EXTRA_LONG_UTF8
    HAS_GETPGRP
    HAS_GROUP
    HAS_HTONL
    HAS_HTONS
    HAS_IOCTL
    HAS_KILL
    HAS_NONLATIN1_FOLD_CLOSURE
    HAS_NTOHL
    HAS_NTOHS
    HAS_PASSWD
    HAS_POSIX_2008_LOCALE
    HAS_PTHREAD_UNCHECKED_GETSPECIFIC_NP
    HAS_SETPGRP
    HAS_SETREGID
    HAS_SETREUID
    HAS_UTIME
    HAS_WAIT
    hasWARNBIT
    HASWIDTH
    HEK_BASESIZE
    HeKEY_hek
    HeKEY_sv
    HEKf
    HEKf256
    HEKf256_QUOTEDPREFIX
    HEKfARG
    HeKFLAGS
    HEK_FLAGS
    HEKf_QUOTEDPREFIX
    HEK_HASH
    HEK_KEY
    HEK_LEN
    HeKLEN_UTF8
    HeKUTF8
    HEK_UTF8
    HEK_UTF8_off
    HEK_UTF8_on
    HeKWASUTF8
    HEK_WASUTF8
    HEK_WASUTF8_off
    HEK_WASUTF8_on
    HeNEXT
    HINT_ALL_STRICT
    HINT_ASCII_ENCODING
    HINT_BLOCK_SCOPE
    HINT_BYTES
    HINT_EXPLICIT_STRICT_REFS
    HINT_EXPLICIT_STRICT_SUBS
    HINT_EXPLICIT_STRICT_VARS
    HINT_FEATURE_MASK
    HINT_FILETEST_ACCESS
    HINT_INTEGER
    HINT_LEXICAL_IO_IN
    HINT_LEXICAL_IO_OUT
    HINT_LOCALE
    HINT_LOCALIZE_HH
    HINT_NEW_BINARY
    HINT_NEW_FLOAT
    HINT_NEW_INTEGER
    HINT_NEW_RE
    HINT_NEW_STRING
    HINT_NO_AMAGIC
    HINT_RE_EVAL
    HINT_RE_FLAGS
    HINT_RE_TAINT
    HINTS_DEFAULT
    HINTS_REFCNT_INIT
    HINTS_REFCNT_TERM
    HINT_STRICT_REFS
    HINT_STRICT_SUBS
    HINT_STRICT_VARS
    HINT_UNI_8_BIT
    HINT_UTF8
    HS_APIVERLEN_MAX
    HS_CXT
    HSf_IMP_CXT
    HSf_NOCHK
    HSf_POPMARK
    HSf_SETXSUBFN
    HS_GETAPIVERLEN
    HS_GETINTERPSIZE
    HS_GETXSVERLEN
    HS_KEY
    HS_KEYp
    HSm_APIVERLEN
    HSm_INTRPSIZE
    HSm_KEY_MATCH
    HSm_XSVERLEN
    HS_XSVERLEN_MAX
    htoni
    htovl
    htovs
    HvAMAGIC
    HvAMAGIC_off
    HvAMAGIC_on
    HvARRAY
    HvAUX
    HvAUXf_IS_CLASS
    HvAUXf_NO_DEREF
    HvAUXf_SCAN_STASH
    HvCLASS_IS_SEALED
    HvCLASSf_SEALED
    HV_DELETE
    HV_DISABLE_UVAR_XKEY
    HvEITER
    HvEITER_get
    HvEITER_set
    HvENAME_get
    HvENAME_HEK
    HvENAME_HEK_NN
    HvENAMELEN_get
    HV_FETCH_EMPTY_HE
    HV_FETCH_ISEXISTS
    HV_FETCH_ISSTORE
    HV_FETCH_JUST_SV
    HV_FETCH_LVALUE
    HvHasENAME
    HvHasENAME_HEK
    HvHASKFLAGS
    HvHASKFLAGS_off
    HvHASKFLAGS_on
    HvHasNAME
    HVhek_ENABLEHVKFLAGS
    HVhek_FREEKEY
    HVhek_KEYCANONICAL
    HVhek_NOTSHARED
    HVhek_PLACEHOLD
    HVhek_UTF8
    HVhek_WASUTF8
    HvKEYS
    HvLASTRAND_get
    HvLAZYDEL
    HvLAZYDEL_off
    HvLAZYDEL_on
    HvMAX
    HvNAME_HEK
    HvNAME_HEK_NN
    HvPLACEHOLDERS
    HvPLACEHOLDERS_get
    HvPLACEHOLDERS_set
    HvRAND_get
    HvRITER
    HvRITER_get
    HvRITER_set
    HvSHAREKEYS
    HvSHAREKEYS_off
    HvSHAREKEYS_on
    HvSTASH_IS_CLASS
    HvTOTALKEYS
    HvUSEDKEYS
    HYPHEN_UTF8
    I16_MAX
    I16_MIN
    I32_MAX
    I32_MAX_P1
    I32_MIN
    I8_TO_NATIVE
    I8_TO_NATIVE_UTF8
    IGNORE_PAT_MOD
    I_LIMITS
    ILLEGAL_UTF8_BYTE
    IN_BYTES
    INCLUDE_PROTOTYPES
    INCMARK
    INCPUSH_APPLLIB_EXP
    INCPUSH_APPLLIB_OLD_EXP
    INCPUSH_ARCHLIB_EXP
    INCPUSH_PRIVLIB_EXP
    INCPUSH_SITEARCH_EXP
    INCPUSH_SITELIB_EXP
    INCPUSH_SITELIB_STEM
    INFNAN_NV_U8_DECL
    INFNAN_U8_NV_DECL
    init_os_extras
    INIT_THREADS
    INIT_TRACK_MEMPOOL
    IN_LC
    IN_LC_ALL_COMPILETIME
    IN_LC_ALL_RUNTIME
    IN_LC_COMPILETIME
    IN_LC_PARTIAL_COMPILETIME
    IN_LC_PARTIAL_RUNTIME
    IN_LC_RUNTIME
    IN_PARENS_PASS
    inRANGE
    IN_SOME_LOCALE_FORM
    IN_SOME_LOCALE_FORM_COMPILETIME
    IN_SOME_LOCALE_FORM_RUNTIME
    INT_64_T
    INT_PAT_MODS
    IN_UNI_8_BIT
    IN_UTF8_CTYPE_LOCALE
    IN_UTF8_TURKIC_LOCALE
    INVLIST_INDEX
    IoANY
    IOCPARM_LEN
    IOf_ARGV
    IOf_DIDTOP
    IOf_FAKE_DIRP
    IOf_NOLINE
    IOf_START
    IoTYPE_APPEND
    IoTYPE_CLOSED
    IoTYPE_IMPLICIT
    IoTYPE_NUMERIC
    IoTYPE_PIPE
    IoTYPE_RDONLY
    IoTYPE_RDWR
    IoTYPE_SOCKET
    IoTYPE_STD
    IoTYPE_WRONLY
    IPERLSYS_H
    isALNUMC_LC_utf8_safe
    isALNUMC_uni
    isALNUMC_utf8
    isALNUMC_utf8_safe
    isALNUM_lazy_if_safe
    isALNUM_LC_utf8
    isALNUM_LC_utf8_safe
    isALNUMU
    isALNUM_uni
    isALNUM_utf8
    isALNUM_utf8_safe
    isALPHA_FOLD_EQ
    isALPHA_FOLD_NE
    isALPHA_LC_utf8
    isALPHANUMERIC_LC_utf8
    isALPHANUMERIC_uni
    isALPHAU
    isALPHA_uni
    isASCII_LC_utf8
    isASCII_uni
    ISA_VERSION_OBJ
    isBACKSLASHED_PUNCT
    isBLANK_LC_uni
    isBLANK_LC_utf8
    isBLANK_uni
    isCASED_LC
    isCHARNAME_CONT
    isCNTRL_LC_utf8
    isCNTRL_uni
    isDIGIT_LC_utf8
    isDIGIT_uni
    is_FOLDS_TO_MULTI_utf8
    isGRAPH_LC_utf8
    isGRAPH_uni
    isGV
    isGV_with_GP_off
    isGV_with_GP_on
    is_HANGUL_ED_utf8_safe
    is_HORIZWS_cp_high
    is_HORIZWS_high
    isIDCONT_LC_utf8
    isIDCONT_uni
    isIDFIRST_lazy_if_safe
    isIDFIRST_LC_utf8
    isIDFIRST_uni
    is_LARGER_NON_CHARS_utf8
    is_LAX_VERSION
    isLEXWARN_off
    isLEXWARN_on
    is_LNBREAK_latin1_safe
    is_LNBREAK_safe
    is_LNBREAK_utf8_safe
    isLOWER_LC_utf8
    isLOWER_uni
    is_MULTI_CHAR_FOLD_latin1_safe
    is_MULTI_CHAR_FOLD_utf8_safe
    isNON_BRACE_QUANTIFIER
    is_NONCHAR_utf8_safe
    IS_NUMERIC_RADIX
    IS_PADCONST
    IS_PADGV
    is_PATWS_safe
    is_posix_ALPHA
    is_posix_ALPHANUMERIC
    is_posix_ASCII
    is_posix_BLANK
    is_posix_CASED
    is_posix_CNTRL
    is_posix_DIGIT
    is_posix_GRAPH
    is_posix_IDFIRST
    is_posix_LOWER
    is_posix_PRINT
    is_posix_PUNCT
    is_posix_SPACE
    is_posix_UPPER
    is_posix_WORDCHAR
    is_posix_XDIGIT
    isPRINT_LC_utf8
    isPRINT_uni
    is_PROBLEMATIC_LOCALE_FOLD_cp
    is_PROBLEMATIC_LOCALE_FOLDEDS_START_cp
    is_PROBLEMATIC_LOCALE_FOLDEDS_START_utf8
    is_PROBLEMATIC_LOCALE_FOLD_utf8
    isPSXSPC_LC_utf8
    isPSXSPC_uni
    isPUNCT_LC_utf8
    isPUNCT_uni
    isQUANTIFIER
    is_QUOTEMETA_high
    isREGEXP
    IS_SAFE_PATHNAME
    is_SHORTER_NON_CHARS_utf8
    isSPACE_LC_utf8
    isSPACE_uni
    is_SPACE_utf8_safe_backwards
    is_STRICT_VERSION
    is_SURROGATE_utf8
    is_SURROGATE_utf8_safe
    I_STDARG
    is_THREE_CHAR_FOLD_HEAD_latin1_safe
    is_THREE_CHAR_FOLD_HEAD_utf8_safe
    is_THREE_CHAR_FOLD_latin1_safe
    is_THREE_CHAR_FOLD_utf8_safe
    isU8_ALPHA_LC
    isU8_ALPHANUMERIC_LC
    isU8_ASCII_LC
    isU8_BLANK_LC
    isU8_CASED_LC
    isU8_CNTRL_LC
    isU8_DIGIT_LC
    isU8_GRAPH_LC
    isU8_IDFIRST_LC
    isU8_LOWER_LC
    isU8_PRINT_LC
    isU8_PUNCT_LC
    isU8_SPACE_LC
    isU8_UPPER_LC
    isU8_WORDCHAR_LC
    isU8_XDIGIT_LC
    isUNICODE_POSSIBLY_PROBLEMATIC
    isUPPER_LC_utf8
    isUPPER_uni
    IS_UTF8_CHAR
    isUTF8_POSSIBLY_PROBLEMATIC
    is_VERTWS_cp_high
    is_VERTWS_high
    isVERTWS_uni
    isVERTWS_utf8
    isVERTWS_utf8_safe
    isVERTWS_uvchr
    isWARNf_on
    isWARN_on
    isWARN_ONCE
    isWORDCHAR_lazy_if_safe
    isWORDCHAR_LC_utf8
    isWORDCHAR_uni
    is_XDIGIT_cp_high
    is_XDIGIT_high
    isXDIGIT_LC_utf8
    isXDIGIT_uni
    is_XPERLSPACE_cp_high
    is_XPERLSPACE_high
    IV_MAX_P1
    JE_OLD_STACK_HWM_restore
    JE_OLD_STACK_HWM_save
    JE_OLD_STACK_HWM_zero
    JMPENV_BOOTSTRAP
    JMPENV_POP
    JOIN
    kBINOP
    kCOP
    KEEPCOPY_PAT_MOD
    KEEPCOPY_PAT_MODS
    KELVIN_SIGN
    KEY_abs
    KEY_accept
    KEY_ADJUST
    KEY_alarm
    KEY_all
    KEY_and
    KEY_any
    KEY_atan2
    KEY_AUTOLOAD
    KEY_BEGIN
    KEY_bind
    KEY_binmode
    KEY_bless
    KEY_break
    KEY_caller
    KEY_catch
    KEY_chdir
    KEY_CHECK
    KEY_chmod
    KEY_chomp
    KEY_chop
    KEY_chown
    KEY_chr
    KEY_chroot
    KEY_class
    KEY_close
    KEY_closedir
    KEY_cmp
    KEY_connect
    KEY_continue
    KEY_cos
    KEY_crypt
    KEY_dbmclose
    KEY_dbmopen
    KEY_default
    KEY_defer
    KEY_defined
    KEY_delete
    KEY_DESTROY
    KEY_die
    KEY_do
    KEY_dump
    KEY_each
    KEY_else
    KEY_elsif
    KEY_END
    KEY_endgrent
    KEY_endhostent
    KEY_endnetent
    KEY_endprotoent
    KEY_endpwent
    KEY_endservent
    KEY_eof
    KEY_eq
    KEY_eval
    KEY_evalbytes
    KEY_exec
    KEY_exists
    KEY_exit
    KEY_exp
    KEY_fc
    KEY_fcntl
    KEY_field
    KEY_fileno
    KEY_finally
    KEY_flock
    KEY_for
    KEY_foreach
    KEY_fork
    KEY_format
    KEY_formline
    KEY_ge
    KEY_getc
    KEY_getgrent
    KEY_getgrgid
    KEY_getgrnam
    KEY_gethostbyaddr
    KEY_gethostbyname
    KEY_gethostent
    KEY_getlogin
    KEY_getnetbyaddr
    KEY_getnetbyname
    KEY_getnetent
    KEY_getpeername
    KEY_getpgrp
    KEY_getppid
    KEY_getpriority
    KEY_getprotobyname
    KEY_getprotobynumber
    KEY_getprotoent
    KEY_getpwent
    KEY_getpwnam
    KEY_getpwuid
    KEY_getservbyname
    KEY_getservbyport
    KEY_getservent
    KEY_getsockname
    KEY_getsockopt
    KEY_getspnam
    KEY_given
    KEY_glob
    KEY_gmtime
    KEY_goto
    KEY_grep
    KEY_gt
    KEY_hex
    KEY_if
    KEY_index
    KEY_INIT
    KEY_int
    KEY_ioctl
    KEY_isa
    KEY_join
    KEY_keys
    KEY_kill
    KEY_last
    KEY_lc
    KEY_lcfirst
    KEY_le
    KEY_length
    KEY_link
    KEY_listen
    KEY_local
    KEY_localtime
    KEY_lock
    KEY_log
    KEY_lstat
    KEY_lt
    KEY_m
    KEY_map
    KEY_method
    KEY_mkdir
    KEY_msgctl
    KEY_msgget
    KEY_msgrcv
    KEY_msgsnd
    KEY_my
    KEY_ne
    KEY_next
    KEY_no
    KEY_not
    KEY_NULL
    KEY_oct
    KEY_open
    KEY_opendir
    KEY_or
    KEY_ord
    KEY_our
    KEY_pack
    KEY_package
    KEY_pipe
    KEY_pop
    KEY_pos
    KEY_print
    KEY_printf
    KEY_prototype
    KEY_push
    KEY_q
    KEY_qq
    KEY_qr
    KEY_quotemeta
    KEY_qw
    KEY_qx
    KEY_rand
    KEY_read
    KEY_readdir
    KEY_readline
    KEY_readlink
    KEY_readpipe
    KEY_recv
    KEY_redo
    KEY_ref
    KEY_rename
    KEY_require
    KEY_reset
    KEY_return
    KEY_reverse
    KEY_rewinddir
    KEY_rindex
    KEY_rmdir
    KEY_s
    KEY_say
    KEY_scalar
    KEY_seek
    KEY_seekdir
    KEY_select
    KEY_semctl
    KEY_semget
    KEY_semop
    KEY_send
    KEY_setgrent
    KEY_sethostent
    KEY_setnetent
    KEY_setpgrp
    KEY_setpriority
    KEY_setprotoent
    KEY_setpwent
    KEY_setservent
    KEY_setsockopt
    KEY_shift
    KEY_shmctl
    KEY_shmget
    KEY_shmread
    KEY_shmwrite
    KEY_shutdown
    KEY_sigvar
    KEY_sin
    KEY_sleep
    KEY_socket
    KEY_socketpair
    KEY_sort
    KEY_splice
    KEY_split
    KEY_sprintf
    KEY_sqrt
    KEY_srand
    KEY_stat
    KEY_state
    KEY_study
    KEY_sub
    KEY_substr
    KEY_symlink
    KEY_syscall
    KEY_sysopen
    KEY_sysread
    KEY_sysseek
    KEY_system
    KEY_syswrite
    KEY_tell
    KEY_telldir
    KEY_tie
    KEY_tied
    KEY_time
    KEY_times
    KEY_tr
    KEY_truncate
    KEY_try
    KEY_uc
    KEY_ucfirst
    KEY_umask
    KEY_undef
    KEY_UNITCHECK
    KEY_unless
    KEY_unlink
    KEY_unpack
    KEY_unshift
    KEY_untie
    KEY_until
    KEY_use
    KEY_utime
    KEY_values
    KEY_vec
    KEY_wait
    KEY_waitpid
    KEY_wantarray
    KEY_warn
    KEY_when
    KEY_while
    KEYWORD_PLUGIN_DECLINE
    KEYWORD_PLUGIN_EXPR
    KEYWORD_PLUGIN_MUTEX_INIT
    KEYWORD_PLUGIN_MUTEX_LOCK
    KEYWORD_PLUGIN_MUTEX_TERM
    KEYWORD_PLUGIN_MUTEX_UNLOCK
    KEYWORD_PLUGIN_STMT
    KEY_write
    KEY_x
    KEY_xor
    KEY_y
    kGVOP_gv
    kLISTOP
    kLOGOP
    kLOOP
    kMETHOP
    kPADOP
    kPMOP
    kPVOP
    kSVOP
    kSVOP_sv
    kUNOP
    kUNOP_AUX
    LARGE_HASH_HEURISTIC
    LATIN_CAPITAL_LETTER_A_WITH_RING_ABOVE
    LATIN_CAPITAL_LETTER_A_WITH_RING_ABOVE_NATIVE
    LATIN_CAPITAL_LETTER_I_WITH_DOT_ABOVE
    LATIN_CAPITAL_LETTER_I_WITH_DOT_ABOVE_UTF8
    LATIN_CAPITAL_LETTER_SHARP_S
    LATIN_CAPITAL_LETTER_SHARP_S_UTF8
    LATIN_CAPITAL_LETTER_Y_WITH_DIAERESIS
    LATIN_SMALL_LETTER_A_WITH_RING_ABOVE
    LATIN_SMALL_LETTER_A_WITH_RING_ABOVE_NATIVE
    LATIN_SMALL_LETTER_DOTLESS_I
    LATIN_SMALL_LETTER_DOTLESS_I_UTF8
    LATIN_SMALL_LETTER_LONG_S
    LATIN_SMALL_LETTER_LONG_S_UTF8
    LATIN_SMALL_LETTER_SHARP_S
    LATIN_SMALL_LETTER_SHARP_S_NATIVE
    LATIN_SMALL_LETTER_SHARP_S_UTF8
    LATIN_SMALL_LETTER_Y_WITH_DIAERESIS
    LATIN_SMALL_LETTER_Y_WITH_DIAERESIS_NATIVE
    LATIN_SMALL_LIGATURE_LONG_S_T
    LATIN_SMALL_LIGATURE_LONG_S_T_UTF8
    LATIN_SMALL_LIGATURE_ST
    LATIN_SMALL_LIGATURE_ST_UTF8
    LC_COLLATE_LOCK
    LC_COLLATE_UNLOCK
    LC_NUMERIC_LOCK
    LC_NUMERIC_UNLOCK
    LEAVE_SCOPE
    LEX_NOTPARSING
    LF_NATIVE
    LIB_INVARG
    LINE_Tf
    LOC
    LOCALE_INIT
    LOCALE_LOCK
    LOCALE_PAT_MOD
    LOCALE_PAT_MODS
    LOCALE_READ_LOCK
    LOCALE_READ_UNLOCK
    LOCALE_TERM
    LOCALE_UNLOCK
    LOCAL_PATCH_COUNT
    LOCALTIME_LOCK
    LOCALTIME_UNLOCK
    LOCK_DOLLARZERO_MUTEX
    LOCK_LC_NUMERIC_STANDARD
    LONGDOUBLE_BIG_ENDIAN
    LONGDOUBLE_DOUBLEDOUBLE
    LONG_DOUBLE_EQUALS_DOUBLE
    LONGDOUBLE_LITTLE_ENDIAN
    LONGDOUBLE_MIX_ENDIAN
    LONGDOUBLE_VAX_ENDIAN
    LONGDOUBLE_X86_80_BIT
    LOOP_PAT_MODS
    lsbit_pos
    LvFLAGS
    LVf_NEG_LEN
    LVf_NEG_OFF
    LVf_OUT_OF_RANGE
    LVRET
    LvSTARGOFF
    LvTARG
    LvTARGLEN
    LvTARGOFF
    LvTYPE
    MADE_EXACT_TRIE
    MADE_JUMP_TRIE
    MADE_TRIE
    MALFORMED_UTF8_DIE
    MALFORMED_UTF8_WARN
    MALLOC_CHECK_TAINT
    MALLOC_CHECK_TAINT2
    MALLOC_INIT
    MALLOC_OVERHEAD
    MALLOC_TERM
    MALLOC_TOO_LATE_FOR
    MARKER1
    MARKER2
    MARK_NAUGHTY
    MARK_NAUGHTY_EXP
    MAXARG
    MAXARG3
    MAX_FOLD_FROMS
    MAX_LEGAL_CP
    MAX_MATCHES
    MAXO
    MAXPATHLEN
    MAX_PORTABLE_UTF8_TWO_BYTE
    MAX_RECURSE_EVAL_NOCHANGE_DEPTH
    MAX_SAVEt
    MAXSYSFD
    MAX_UNICODE_UTF8
    MAX_UTF8_TWO_BYTE
    MDEREF_ACTION_MASK
    MDEREF_AV_gvav_aelem
    MDEREF_AV_gvsv_vivify_rv2av_aelem
    MDEREF_AV_padav_aelem
    MDEREF_AV_padsv_vivify_rv2av_aelem
    MDEREF_AV_pop_rv2av_aelem
    MDEREF_AV_vivify_rv2av_aelem
    MDEREF_FLAG_last
    MDEREF_HV_gvhv_helem
    MDEREF_HV_gvsv_vivify_rv2hv_helem
    MDEREF_HV_padhv_helem
    MDEREF_HV_padsv_vivify_rv2hv_helem
    MDEREF_HV_pop_rv2hv_helem
    MDEREF_HV_vivify_rv2hv_helem
    MDEREF_INDEX_const
    MDEREF_INDEX_gvsv
    MDEREF_INDEX_MASK
    MDEREF_INDEX_none
    MDEREF_INDEX_padsv
    MDEREF_MASK
    MDEREF_reload
    MDEREF_SHIFT
    memBEGINPs
    memBEGINs
    MEMBER_TO_FPTR
    memENDPs
    memENDs
    memGE
    memGT
    memLE
    MEM_LOG_ALLOC
    MEM_LOG_DEL_SV
    MEM_LOG_FREE
    MEM_LOG_NEW_SV
    MEM_LOG_REALLOC
    memLT
    MEM_SIZE
    MEM_SIZE_MAX
    MEM_WRAP_CHECK
    MEM_WRAP_CHECK_1
    MEM_WRAP_CHECK_s
    MEXTEND
    MGf_BYTES
    MGf_GSKIP
    MGf_MINMATCH
    MGf_REFCOUNTED
    MGf_REQUIRE_GV
    MGf_TAINTEDDIR
    MgPV
    MgPV_const
    MgPV_nolen_const
    MgSV
    MgTAINTEDDIR
    MgTAINTEDDIR_off
    MgTAINTEDDIR_on
    MICRO_SIGN
    MICRO_SIGN_NATIVE
    MICRO_SIGN_UTF8
    MI_INIT_WORKAROUND_PACK
    MIN_OFFUNI_VARIANT_CP
    Mkdir
    MKTIME_LOCK
    MKTIME_UNLOCK
    M_PAT_MODS
    msbit_pos
    MSPAGAIN
    MSVC_DIAG_IGNORE
    MSVC_DIAG_IGNORE_DECL
    MSVC_DIAG_IGNORE_STMT
    MSVC_DIAG_RESTORE
    MSVC_DIAG_RESTORE_DECL
    MSVC_DIAG_RESTORE_STMT
    MULTILINE_PAT_MOD
    MUST_RESTART
    MUTEX_DESTROY
    MUTEX_INIT
    MUTEX_INIT_NEEDS_MUTEX_ZEROED
    MUTEX_LOCK
    MUTEX_UNLOCK
    my_binmode
    MY_CXT_INDEX
    MY_CXT_INIT_ARG
    my_lstat
    my_stat
    namedclass_to_classnum
    NAN_COMPARE_BROKEN
    NATIVE8_TO_UNI
    NATIVE_BYTE_IS_INVARIANT
    NATIVE_SKIP
    NATIVE_TO_ASCII
    NATIVE_TO_I8
    NATIVE_TO_UTF
    NATIVE_UTF8_TO_I8
    nBIT_MASK
    nBIT_UMAX
    NBSP_NATIVE
    NBSP_UTF8
    NDEBUG
    NEED_UTF8
    NEGATE_2IV
    NEGATE_2UV
    NEGATIVE_INDICES_VAR
    NETDB_R_OBSOLETE
    New
    new_body_allocated
    new_body_from_arena
    Newc
    new_NOARENA
    new_NOARENAZ
    NewOp
    NewOpSz
    new_SV
    NEWSV
    NEW_VERSION
    new_XNV
    new_XPVMG
    new_XPVNV
    Newz
    NEXT_LINE_CHAR
    NOARENA
    NOCAPTURE_PAT_MOD
    NOCAPTURE_PAT_MODS
    NO_ENV_ARRAY_IN_MAIN
    NO_ENVIRON_ARRAY
    NofAMmeth
    NOLINE
    NONDESTRUCT_PAT_MOD
    NONDESTRUCT_PAT_MODS
    NONV
    NORETURN_FUNCTION_END
    NORMAL
    NO_TAINT_SUPPORT
    NOTE3
    NOT_REACHED
    NSIG
    ntohi
    Null
    Nullfp
    Nullgv
    Nullhe
    Nullhek
    Nullop
    NUM_ANYOF_CODE_POINTS
    NV_BIG_ENDIAN
    NV_DIG
    NV_EPSILON
    NV_IMPLICIT_BIT
    NV_INF
    NV_LITTLE_ENDIAN
    NV_MANT_DIG
    NV_MAX
    NV_MAX_10_EXP
    NV_MAX_EXP
    NV_MIN
    NV_MIN_10_EXP
    NV_MIN_EXP
    NV_MIX_ENDIAN
    NV_NAN
    NV_NAN_BITS
    NV_NAN_IS_QUIET
    NV_NAN_IS_SIGNALING
    NV_NAN_PAYLOAD_MASK
    NV_NAN_PAYLOAD_MASK_IEEE_754_128_BE
    NV_NAN_PAYLOAD_MASK_IEEE_754_128_LE
    NV_NAN_PAYLOAD_MASK_IEEE_754_64_BE
    NV_NAN_PAYLOAD_MASK_IEEE_754_64_LE
    NV_NAN_PAYLOAD_MASK_SKIP_EIGHT
    NV_NAN_PAYLOAD_PERM
    NV_NAN_PAYLOAD_PERM_0_TO_7
    NV_NAN_PAYLOAD_PERM_7_TO_0
    NV_NAN_PAYLOAD_PERM_IEEE_754_128_BE
    NV_NAN_PAYLOAD_PERM_IEEE_754_128_LE
    NV_NAN_PAYLOAD_PERM_IEEE_754_64_BE
    NV_NAN_PAYLOAD_PERM_IEEE_754_64_LE
    NV_NAN_PAYLOAD_PERM_SKIP_EIGHT
    NV_NAN_QS_BIT
    NV_NAN_QS_BIT_OFFSET
    NV_NAN_QS_BIT_SHIFT
    NV_NAN_QS_BYTE
    NV_NAN_QS_BYTE_OFFSET
    NV_NAN_QS_QUIET
    NV_NAN_QS_SIGNALING
    NV_NAN_QS_TEST
    NV_NAN_QS_XOR
    NV_NAN_SET_QUIET
    NV_NAN_SET_SIGNALING
    NV_VAX_ENDIAN
    NV_WITHIN_IV
    NV_WITHIN_UV
    NV_X86_80_BIT
    OA_AVREF
    OA_BASEOP_OR_UNOP
    OA_CLASS_MASK
    OA_CVREF
    OA_DANGEROUS
    OA_DEFGV
    OA_FILEREF
    OA_FILESTATOP
    OA_FOLDCONST
    OA_HVREF
    OA_LIST
    OA_LOOPEXOP
    OA_MARK
    OA_METHOP
    OA_OPTIONAL
    OA_OTHERINT
    OA_RETSCALAR
    OA_SCALAR
    OA_SCALARREF
    OASHIFT
    OA_TARGET
    OA_TARGLEX
    OA_UNOP_AUX
    ObjectFIELDS
    ObjectITERSVAT
    ObjectMAXFIELD
    OCSHIFT
    OCTAL_VALUE
    OFFUNI_IS_INVARIANT
    OFFUNISKIP
    ONCE_PAT_MOD
    ONCE_PAT_MODS
    ONE_IF_EBCDIC_ZERO_IF_NOT
    ONLY_LOCALE_MATCHES_INDEX
    OOB_NAMEDCLASS
    OOB_UNICODE
    opASSIGN
    OP_CHECK_MUTEX_INIT
    OP_CHECK_MUTEX_LOCK
    OP_CHECK_MUTEX_TERM
    OP_CHECK_MUTEX_UNLOCK
    OPCODE
    OPf_FOLDED
    OPf_KNOW
    OPf_LIST
    OPf_MOD
    OPf_PARENS
    OP_FREED
    OPf_REF
    OPf_SPECIAL
    OPf_STACKED
    OPf_WANT
    OPf_WANT_LIST
    OPf_WANT_SCALAR
    OPf_WANT_VOID
    OP_GIMME
    OP_GIMME_REVERSE
    OP_IS_DIRHOP
    OP_IS_FILETEST
    OP_IS_FILETEST_ACCESS
    OP_IS_INFIX_BIT
    OP_IS_NUMCOMPARE
    OP_IS_SOCKET
    OP_IS_STAT
    OP_LVALUE_NO_CROAK
    OPpALLOW_FAKE
    OPpARG1_MASK
    OPpARG2_MASK
    OPpARG3_MASK
    OPpARG4_MASK
    OPpARGELEM_AV
    OPpARGELEM_HV
    OPpARGELEM_MASK
    OPpARGELEM_SV
    OPpARG_IF_FALSE
    OPpARG_IF_UNDEF
    OPpASSIGN_BACKWARDS
    OPpASSIGN_COMMON_AGG
    OPpASSIGN_COMMON_RC1
    OPpASSIGN_COMMON_SCALAR
    OPpASSIGN_CV_TO_GV
    OPpASSIGN_TRUEBOOL
    OPpAVHVSWITCH_MASK
    OPpCONCAT_NESTED
    OPpCONST_BARE
    OPpCONST_ENTERED
    OPpCONST_NOVER
    OPpCONST_SHORTCIRCUIT
    OPpCONST_STRICT
    OPpCONST_TOKEN_BITS
    OPpCONST_TOKEN_FILE
    OPpCONST_TOKEN_LINE
    OPpCONST_TOKEN_MASK
    OPpCONST_TOKEN_PACKAGE
    OPpCONST_TOKEN_SHIFT
    OPpCOREARGS_DEREF1
    OPpCOREARGS_DEREF2
    OPpCOREARGS_PUSHMARK
    OPpCOREARGS_SCALARMOD
    OPpDEFER_FINALLY
    OPpDEREF
    OPpDEREF_AV
    OPpDEREF_HV
    OPpDEREF_SV
    OPpDONT_INIT_GV
    OPpEMPTYAVHV_IS_HV
    OPpENTERSUB_DB
    OPpENTERSUB_HASTARG
    OPpENTERSUB_INARGS
    OPpENTERSUB_LVAL_MASK
    OPpENTERSUB_NOPAREN
    OPpEVAL_BYTES
    OPpEVAL_COPHH
    OPpEVAL_EVALSV
    OPpEVAL_HAS_HH
    OPpEVAL_RE_REPARSING
    OPpEVAL_UNICODE
    OPpEXISTS_SUB
    OPpFLIP_LINENUM
    OPpFT_ACCESS
    OPpFT_AFTER_t
    OPpFT_STACKED
    OPpFT_STACKING
    OPpHELEMEXISTSOR_DELETE
    OPpHINT_STRICT_REFS
    OPpHUSH_VMSISH
    OPpINDEX_BOOLNEG
    OPpINITFIELD_AV
    OPpINITFIELD_HV
    OPpINITFIELDS
    OPpITER_DEF
    OPpITER_INDEXED
    OPpITER_REFALIAS
    OPpITER_REVERSED
    OPpKVSLICE
    OPpLIST_GUESSED
    OPpLVAL_DEFER
    OPpLVAL_INTRO
    OPpLVALUE
    OPpLVREF_AV
    OPpLVREF_CV
    OPpLVREF_ELEM
    OPpLVREF_HV
    OPpLVREF_ITER
    OPpLVREF_SV
    OPpLVREF_TYPE
    OPpMAYBE_LVSUB
    OPpMAYBE_TRUEBOOL
    OPpMAY_RETURN_CONSTANT
    OPpMETH_NO_BAREWORD_IO
    op_pmflags
    op_pmoffset
    OPpMULTICONCAT_APPEND
    OPpMULTICONCAT_FAKE
    OPpMULTICONCAT_STRINGIFY
    OPpMULTIDEREF_DELETE
    OPpMULTIDEREF_EXISTS
    OPpOFFBYONE
    OPpOPEN_IN_CRLF
    OPpOPEN_IN_RAW
    OPpOPEN_OUT_CRLF
    OPpOPEN_OUT_RAW
    OPpOUR_INTRO
    OPpPADHV_ISKEYS
    OPpPADRANGE_COUNTMASK
    OPpPADRANGE_COUNTSHIFT
    OPpPAD_STATE
    OPpPV_IS_UTF8
    OPpREFCOUNTED
    OPpREPEAT_DOLIST
    OPpREVERSE_INPLACE
    OPpRV2HV_ISKEYS
    OPpSLICE
    OPpSLICEWARNING
    OPpSORT_DESCEND
    OPpSORT_INPLACE
    OPpSORT_INTEGER
    OPpSORT_NUMERIC
    OPpSORT_REVERSE
    OPpSPLIT_ASSIGN
    OPpSPLIT_IMPLIM
    OPpSPLIT_LEX
    OPpSTATEMENT
    OPpSUBSTR_REPL_FIRST
    OPpTARGET_MY
    OPpTRANS_ALL
    OPpTRANS_BITS
    OPpTRANS_CAN_FORCE_UTF8
    OPpTRANS_COMPLEMENT
    OPpTRANS_DELETE
    OPpTRANS_FROM_UTF
    OPpTRANS_GROWS
    OPpTRANS_IDENTICAL
    OPpTRANS_MASK
    OPpTRANS_ONLY_UTF8_INVARIANTS
    OPpTRANS_SHIFT
    OPpTRANS_SQUASH
    OPpTRANS_TO_UTF
    OPpTRANS_USE_SVOP
    OPpTRUEBOOL
    OPpUNDEF_KEEP_PV
    OPpUSEINT
    OpREFCNT_dec
    OpREFCNT_inc
    OP_REFCNT_INIT
    OP_REFCNT_LOCK
    OpREFCNT_set
    OP_REFCNT_TERM
    OP_REFCNT_UNLOCK
    OP_SIBLING
    OPTIMIZE_INFTY
    OP_TYPE_IS_COP_NN
    OP_TYPE_IS_NN
    OP_TYPE_ISNT
    OP_TYPE_ISNT_AND_WASNT
    OP_TYPE_ISNT_AND_WASNT_NN
    OP_TYPE_ISNT_NN
    OP_TYPE_IS_OR_WAS_NN
    OpTYPE_set
    OutCopFILE
    padadd_FIELD
    padadd_NO_DUP_CHECK
    padadd_OUR
    padadd_STALEOK
    padadd_STATE
    padalloc_NO_SV
    PAD_BASE_SV
    PAD_CLONE_VARS
    PAD_COMPNAME
    PAD_COMPNAME_FLAGS
    PAD_COMPNAME_FLAGS_isOUR
    PAD_COMPNAME_GEN
    PAD_COMPNAME_GEN_set
    PAD_COMPNAME_OURSTASH
    PAD_COMPNAME_PV
    PAD_COMPNAME_SV
    PAD_COMPNAME_TYPE
    PAD_FAKELEX_ANON
    PAD_FAKELEX_MULTI
    padfind_FIELD_OK
    padname_dup_inc
    PADNAMEf_FIELD
    PadnameFIELDINFO
    PadnameFLAGS
    PADNAMEf_LVALUE
    PADNAMEf_OUR
    PADNAME_FROM_PV
    PADNAMEf_STATE
    PADNAMEf_TYPED
    PadnameHasTYPE
    PadnameIsFIELD
    PadnameIsOUR
    PadnameIsSTATE
    PadnameIsSTATE_on
    padnamelist_dup_inc
    PadnamelistMAXNAMED
    PadnamelistREFCNT_inc
    PadnameLVALUE
    PadnameLVALUE_on
    PadnameOURSTASH
    PadnameOURSTASH_set
    PadnameOUTER
    PadnamePROTOCV
    PADNAMEt_LVALUE
    PADNAMEt_OUR
    PADNAMEt_OUTER
    PADNAMEt_STATE
    PADNAMEt_TYPED
    PadnameTYPE
    PadnameTYPE_set
    padnew_CLONE
    padnew_SAVE
    padnew_SAVESUB
    PAD_RESTORE_LOCAL
    PAD_SAVE_LOCAL
    PAD_SAVE_SETNULLPAD
    PAD_SET_CUR
    PAD_SET_CUR_NOSAVE
    PAD_SETSV
    PAD_SV
    PAD_SVl
    panic_write2
    PAREN_OFFSET
    PAREN_SET
    PAREN_TEST
    PARENT_FAKELEX_FLAGS
    PARENT_PAD_INDEX
    PAREN_UNSET
    PATCHLEVEL
    Pause
    PBITVAL
    PBYTE
    PerlEnv_putenv
    PIPE_OPEN_MODE
    PIPESOCK_MODE
    PL_DBsingle
    PL_DBtrace
    PL_last_in_gv
    PL_ofsgv
    PL_rs
    PMf_BASE_SHIFT
    PMf_CHARSET
    PMf_CODELIST_PRIVATE
    PMf_CONST
    PMf_CONTINUE
    PMf_EVAL
    PMf_EXTENDED
    PMf_EXTENDED_MORE
    PMf_FOLD
    PMf_GLOBAL
    PMf_HAS_CV
    PMf_HAS_ERROR
    PMf_IS_QR
    PMf_KEEP
    PMf_KEEPCOPY
    PMf_MULTILINE
    PMf_NOCAPTURE
    PMf_NONDESTRUCT
    PMf_ONCE
    PMf_RETAINT
    PMf_SINGLELINE
    PMf_SPLIT
    PMf_STRICT
    PMf_USED
    PMf_USE_RE_EVAL
    PMf_WILDCARD
    PM_GETRE
    PM_GETRE_raw
    PmopSTASH
    PmopSTASHPV
    PmopSTASHPV_set
    PmopSTASH_set
    PM_SETRE
    PM_SETRE_raw
    PNf
    PNfARG
    PoisonPADLIST
    POISON_SV_HEAD
    POPMARK
    POPpconstx
    POPSTACK
    POPSTACK_TO
    POSIX_CC_COUNT
    POSIX_SETLOCALE_LOCK
    POSIX_SETLOCALE_UNLOCK
    POSTPONED
    PP
    PP_wrapped
    PRESCAN_VERSION
    PRINTF_FORMAT_NULL_OK
    PRIVLIB_EXP
    PRIVSHIFT
    ProgLen
    pthread_addr_t
    PTHREAD_ATFORK
    PTHREAD_ATTR_SETDETACHSTATE
    pthread_condattr_default
    PTHREAD_CREATE
    PTHREAD_CREATE_JOINABLE
    PTHREAD_GETSPECIFIC
    PTHREAD_GETSPECIFIC_INT
    PTHREAD_INIT_SELF
    pthread_key_create
    pthread_keycreate
    pthread_mutexattr_default
    pthread_mutexattr_init
    pthread_mutexattr_settype
    pTHX_1
    pTHX_12
    pTHX_2
    pTHX_3
    pTHX_4
    pTHX_5
    pTHX_6
    pTHX_7
    pTHX_8
    pTHX_9
    pTHX__FORMAT
    pTHX_FORMAT
    pTHXo
    pTHX__VALUE
    pTHX_VALUE
    pTHXx
    PUSH_MULTICALL_FLAGS
    PUSHSTACK
    PUSHSTACKi
    PUSHSTACK_INIT_HWM
    PUSHTARG
    PVf_QUOTEDPREFIX
    pWARN_ALL
    pWARN_NONE
    pWARN_STD
    QR_PAT_MODS
    QUESTION_MARK_CTRL
    RCPVf_ALLOW_EMPTY
    RCPVf_NO_COPY
    RCPVf_USE_STRLEN
    REENABLE_LC_NUMERIC_CHANGES
    REENTRANT_PROTO_B_B
    REENTRANT_PROTO_B_BI
    REENTRANT_PROTO_B_BW
    REENTRANT_PROTO_B_CCD
    REENTRANT_PROTO_B_CCS
    REENTRANT_PROTO_B_IBI
    REENTRANT_PROTO_B_IBW
    REENTRANT_PROTO_B_SB
    REENTRANT_PROTO_B_SBI
    REENTRANT_PROTO_I_BI
    REENTRANT_PROTO_I_BW
    REENTRANT_PROTO_I_CCSBWR
    REENTRANT_PROTO_I_CCSD
    REENTRANT_PROTO_I_CII
    REENTRANT_PROTO_I_CIISD
    REENTRANT_PROTO_I_CSBI
    REENTRANT_PROTO_I_CSBIR
    REENTRANT_PROTO_I_CSBWR
    REENTRANT_PROTO_I_CSBWRE
    REENTRANT_PROTO_I_CSD
    REENTRANT_PROTO_I_CWISBWRE
    REENTRANT_PROTO_I_CWISD
    REENTRANT_PROTO_I_D
    REENTRANT_PROTO_I_H
    REENTRANT_PROTO_I_IBI
    REENTRANT_PROTO_I_IBW
    REENTRANT_PROTO_I_ICBI
    REENTRANT_PROTO_I_ICSBWR
    REENTRANT_PROTO_I_ICSD
    REENTRANT_PROTO_I_ID
    REENTRANT_PROTO_I_IISD
    REENTRANT_PROTO_I_ISBWR
    REENTRANT_PROTO_I_ISD
    REENTRANT_PROTO_I_LISBI
    REENTRANT_PROTO_I_LISD
    REENTRANT_PROTO_I_SB
    REENTRANT_PROTO_I_SBI
    REENTRANT_PROTO_I_SBIE
    REENTRANT_PROTO_I_SBIH
    REENTRANT_PROTO_I_SBIR
    REENTRANT_PROTO_I_SBWR
    REENTRANT_PROTO_I_SBWRE
    REENTRANT_PROTO_I_SD
    REENTRANT_PROTO_I_TISD
    REENTRANT_PROTO_I_TS
    REENTRANT_PROTO_I_TSBI
    REENTRANT_PROTO_I_TSBIR
    REENTRANT_PROTO_I_TSBWR
    REENTRANT_PROTO_I_TsISBWRE
    REENTRANT_PROTO_I_TSR
    REENTRANT_PROTO_I_uISBWRE
    REENTRANT_PROTO_I_UISBWRE
    REENTRANT_PROTO_S_CBI
    REENTRANT_PROTO_S_CCSBI
    REENTRANT_PROTO_S_CIISBIE
    REENTRANT_PROTO_S_CSBI
    REENTRANT_PROTO_S_CSBIE
    REENTRANT_PROTO_S_CWISBIE
    REENTRANT_PROTO_S_CWISBWIE
    REENTRANT_PROTO_S_ICSBI
    REENTRANT_PROTO_S_ISBI
    REENTRANT_PROTO_S_LISBI
    REENTRANT_PROTO_S_SBI
    REENTRANT_PROTO_S_SBIE
    REENTRANT_PROTO_S_SBW
    REENTRANT_PROTO_S_TISBI
    REENTRANT_PROTO_S_TS
    REENTRANT_PROTO_S_TSBI
    REENTRANT_PROTO_S_TSBIE
    REENTRANT_PROTO_S_TWISBIE
    REENTRANT_PROTO_V_D
    REENTRANT_PROTO_V_H
    REENTRANT_PROTO_V_ID
    REENTR_MEMZERO
    REFCOUNTED_HE_EXISTS
    REFCOUNTED_HE_KEY_UTF8
    REGCOMP_INTERNAL_H
    RegexLengthToShowInErrorMessages
    REG_FETCH_ABSOLUTE
    REGNODE_GUTS
    REG_NODE_NUM
    REGNODE_OFFSET
    REGNODE_p
    REGNODE_STEP_OVER
    REGTAIL
    REGTAIL_STUDY
    reg_warn_non_literal_string
    RE_OPTIMIZE_CURLYX_TO_CURLYM
    RE_OPTIMIZE_CURLYX_TO_CURLYN
    REPORT_LOCATION
    REPORT_LOCATION_ARGS
    REQUIRE_BRANCHJ
    REQUIRE_PARENS_PASS
    REQUIRE_UNI_RULES
    REQUIRE_UTF8
    ReREFCNT_dec
    ReREFCNT_inc
    RESTART_PARSE
    RESTORE_ERRNO
    RESTORE_WARNINGS
    RETPUSHNO
    RETPUSHUNDEF
    RETPUSHYES
    RETSETNO
    RETSETTARG
    RETSETUNDEF
    RETSETYES
    RETURN
    RETURN_FAIL_ON_RESTART
    RETURN_FAIL_ON_RESTART_FLAGP
    RETURN_FAIL_ON_RESTART_OR_FLAGS
    RETURNOP
    RETURNX
    RExC_close_parens
    RExC_contains_locale
    RExC_copy_start_in_constructed
    RExC_copy_start_in_input
    RExC_emit
    RExC_emit_start
    RExC_end
    RExC_end_op
    RExC_flags
    RExC_frame_count
    RExC_frame_head
    RExC_frame_last
    RExC_in_lookaround
    RExC_in_multi_char_class
    RExC_in_script_run
    RExC_lastnum
    RExC_lastparse
    RExC_latest_warn_offset
    RExC_logical_npar
    RExC_logical_to_parno
    RExC_logical_total_parens
    RExC_maxlen
    RExC_mysv
    RExC_mysv1
    RExC_mysv2
    RExC_naughty
    RExC_nestroot
    RExC_npar
    RExC_open_parens
    RExC_orig_utf8
    RExC_paren_name_list
    RExC_paren_names
    RExC_parens_buf_size
    RExC_parno_to_logical
    RExC_parno_to_logical_next
    RExC_parse
    RExC_parse_inc
    RExC_parse_inc_by
    RExC_parse_incf
    RExC_parse_inc_if_char
    RExC_parse_inc_safe
    RExC_parse_inc_safef
    RExC_parse_inc_utf8
    RExC_parse_set
    RExC_pm_flags
    RExC_precomp
    RExC_precomp_end
    RExC_recode_x_to_native
    RExC_recurse
    RExC_recurse_count
    RExC_rx
    RExC_rxi
    RExC_rx_sv
    RExC_save_copy_start_in_constructed
    RExC_sawback
    RExC_seen
    RExC_seen_d_op
    RExC_seen_zerolen
    RExC_sets_depth
    RExC_size
    RExC_start
    RExC_strict
    RExC_study_chunk_recursed
    RExC_study_chunk_recursed_bytes
    RExC_study_chunk_recursed_count
    RExC_study_started
    RExC_total_parens
    RExC_uni_semantics
    RExC_unlexed_names
    RExC_use_BRANCHJ
    RExC_utf8
    RExC_warned_WARN_EXPERIMENTAL__REGEX_SETS
    RExC_warned_WARN_EXPERIMENTAL__VLB
    RExC_warn_text
    RExC_whilem_seen
    REXEC_CHECKED
    REXEC_FAIL_ON_UNDERFLOW
    REXEC_IGNOREPOS
    REXEC_NOT_FIRST
    REXEC_SCREAM
    RMS_DIR
    RMS_FAC
    RMS_FEX
    RMS_FNF
    RMS_IFI
    RMS_ISI
    RMS_PRV
    ROTL32
    ROTL64
    ROTL_UV
    ROTR32
    ROTR64
    ROTR_UV
    RsPARA
    RsRECORD
    RsSIMPLE
    RsSNARF
    RUNOPS_DEFAULT
    RV2CVOPCV_FLAG_MASK
    RV2CVOPCV_RETURN_STUB
    RX_CHECK_SUBSTR
    RX_COMPFLAGS
    RX_ENGINE
    RX_EXTFLAGS
    RXf_BASE_SHIFT
    RXf_CHECK_ALL
    RXf_COPY_DONE
    RXf_EVAL_SEEN
    RXf_INTUIT_TAIL
    RXf_IS_ANCHORED
    RXf_MATCH_UTF8
    RXf_PMf_CHARSET
    RXf_PMf_COMPILETIME
    RXf_PMf_EXTENDED_MORE
    RXf_PMf_FLAGCOPYMASK
    RXf_PMf_NOCAPTURE
    RXf_PMf_SPLIT
    RXf_PMf_STD_PMMOD
    RXf_PMf_STD_PMMOD_SHIFT
    RXf_PMf_STRICT
    RXf_TAINTED
    RXf_TAINTED_SEEN
    RXf_UNBOUNDED_QUANTIFIER_SEEN
    RXf_USE_INTUIT
    RXf_USE_INTUIT_ML
    RXf_USE_INTUIT_NOML
    RX_GOFS
    RX_ISTAINTED
    RX_LASTCLOSEPAREN
    RX_LASTPAREN
    RX_LOGICAL_NPARENS
    RX_LOGICAL_TO_PARNO
    RX_MATCH_COPIED_off
    RX_MATCH_COPIED_on
    RX_MATCH_COPIED_set
    RX_MATCH_COPY_FREE
    RX_MATCH_TAINTED
    RX_MATCH_TAINTED_off
    RX_MATCH_TAINTED_on
    RX_MATCH_TAINTED_set
    RX_MATCH_UTF8
    RX_MATCH_UTF8_off
    RX_MATCH_UTF8_on
    RX_MATCH_UTF8_set
    RX_MINLEN
    RX_MINLENRET
    RX_MOTHER_RE
    RX_NPARENS
    RX_OFFSp
    RX_PARNO_TO_LOGICAL
    RX_PARNO_TO_LOGICAL_NEXT
    RXp_COMPFLAGS
    RXp_ENGINE
    RXp_EXTFLAGS
    RXp_GOFS
    RXp_HAS_CUTGROUP
    RXp_ISTAINTED
    RXp_LASTCLOSEPAREN
    RXp_LASTPAREN
    RXp_LOGICAL_NPARENS
    RXp_LOGICAL_TO_PARNO
    RXp_MATCH_COPIED
    RXp_MATCH_COPIED_off
    RXp_MATCH_COPIED_on
    RXp_MATCH_COPY_FREE
    RXp_MATCH_TAINTED
    RXp_MATCH_TAINTED_off
    RXp_MATCH_TAINTED_on
    RXp_MATCH_UTF8
    RXp_MATCH_UTF8_off
    RXp_MATCH_UTF8_on
    RXp_MATCH_UTF8_set
    RXp_MINLEN
    RXp_MINLENRET
    RXp_MOTHER_RE
    RXp_NPARENS
    RXp_OFFSp
    RXp_PAREN_NAMES
    RXp_PARNO_TO_LOGICAL
    RXp_PARNO_TO_LOGICAL_NEXT
    RXp_PPRIVATE
    RXp_PRE_PREFIX
    RX_PPRIVATE
    RXp_QR_ANONCV
    RX_PRECOMP
    RX_PRECOMP_const
    RX_PRELEN
    RX_PRE_PREFIX
    RXp_SAVED_COPY
    RXp_SUBBEG
    RXp_SUBCOFFSET
    RXp_SUBLEN
    RXp_SUBOFFSET
    RXp_SUBSTRS
    RXp_ZERO_LEN
    RX_QR_ANONCV
    RX_REFCNT
    RX_SAVED_COPY
    RX_SUBBEG
    RX_SUBCOFFSET
    RX_SUBLEN
    RX_SUBOFFSET
    RX_SUBSTRS
    RX_TAINT_on
    RX_UTF8
    RX_WRAPLEN
    RX_WRAPPED
    RX_WRAPPED_const
    RX_ZERO_LEN
    safefree
    SAVEADELETE
    SAVECLEARSV
    SAVECOMPILEWARNINGS
    SAVECOMPPAD
    SAVECOPFILE
    SAVECOPFILE_FREE
    SAVECOPFILE_FREE_x
    SAVECOPFILE_x
    SAVECOPLINE
    SAVECOPSTASH_FREE
    SAVECURCOPWARNINGS
    SAVE_ERRNO
    SAVEFREECOPHH
    SAVEFREEPADNAME
    SAVEGENERICPV
    SAVEHDELETE
    SAVEHINTS
    SAVE_MASK
    SAVEOP
    SAVEPADSVANDMORTALIZE
    SAVEPARSER
    SAVESETSVFLAGS
    SAVESHAREDPV
    SAVESWITCHSTACK
    SAVEt_ADELETE
    SAVEt_AELEM
    SAVEt_ALLOC
    SAVEt_APTR
    SAVEt_AV
    SAVEt_BOOL
    SAVEt_CLEARPADRANGE
    SAVEt_CLEARSV
    SAVEt_COMPILE_WARNINGS
    SAVEt_COMPPAD
    SAVEt_CURCOP_WARNINGS
    SAVEt_DELETE
    SAVEt_DESTRUCTOR
    SAVEt_DESTRUCTOR_X
    SAVEt_FREECOPHH
    SAVEt_FREEOP
    SAVEt_FREEPADNAME
    SAVEt_FREEPV
    SAVEt_FREERCPV
    SAVEt_FREE_REXC_STATE
    SAVEt_FREESV
    SAVEt_GENERIC_PVREF
    SAVEt_GENERIC_SVREF
    SAVEt_GP
    SAVEt_GVSLOT
    SAVEt_GVSV
    SAVEt_HELEM
    SAVEt_HINTS
    SAVEt_HINTS_HH
    SAVEt_HPTR
    SAVEt_HV
    SAVEt_I16
    SAVEt_I32
    SAVEt_I32_SMALL
    SAVEt_I8
    SAVE_TIGHT_SHIFT
    SAVEt_INT_SMALL
    SAVEt_ITEM
    SAVEt_IV
    SAVEt_MORTALIZESV
    SAVEt_NSTAB
    SAVEt_OP
    SAVEt_PADSV
    SAVEt_PADSV_AND_MORTALIZE
    SAVEt_PADSV_NULL
    SAVEt_PARSER
    SAVEt_PPTR
    SAVEt_RCPV
    SAVEt_READONLY_OFF
    SAVEt_REGCONTEXT
    SAVEt_SAVESWITCHSTACK
    SAVEt_SET_SVFLAGS
    SAVEt_SHARED_PVREF
    SAVEt_SPTR
    SAVEt_STACK_POS
    SAVEt_STRLEN
    SAVEt_STRLEN_SMALL
    SAVEt_SV
    SAVEt_SVREF
    SAVEt_TMPSFLOOR
    SAVEt_VPTR
    SAVEVPTR
    SAWAMPERSAND_LEFT
    SAWAMPERSAND_MIDDLE
    SAWAMPERSAND_RIGHT
    SBOX32_CHURN_ROUNDS
    SBOX32_MIX3
    SBOX32_MIX4
    SBOX32_STATE_BITS
    SBOX32_STATE_BYTES
    SBOX32_STATE_WORDS
    SBOX32_STATIC_INLINE
    SBOX32_WARN2
    SBOX32_WARN3
    SBOX32_WARN4
    SBOX32_WARN5
    SBOX32_WARN6
    sC
    SCAN_DEF
    SCAN_REPL
    SCAN_TR
    SCAN_VERSION
    SCF_DO_STCLASS
    SCF_DO_STCLASS_AND
    SCF_DO_STCLASS_OR
    SCF_DO_SUBSTR
    SCF_IN_DEFINE
    SCF_SEEN_ACCEPT
    SCF_TRIE_DOING_RESTUDY
    SCF_TRIE_RESTUDY
    SCF_WHILEM_VISITED_POS
    SCOPE_SAVES_SIGNAL_MASK
    Semctl
    semun
    SETERRNO
    SETGRENT_R_HAS_FPTR
    SETi
    SET_MARK_OFFSET
    SETn
    SET_NUMERIC_STANDARD
    SET_NUMERIC_UNDERLYING
    SETp
    SetProgLen
    SETPWENT_R_HAS_FPTR
    SET_recode_x_to_native
    SETs
    SET_SVANY_FOR_BODYLESS_IV
    SET_SVANY_FOR_BODYLESS_NV
    SETTARG
    SET_THR
    SET_THREAD_SELF
    SETu
    SF_BEFORE_EOL
    SF_BEFORE_MEOL
    SF_BEFORE_SEOL
    SF_HAS_EVAL
    SF_HAS_PAR
    SF_IN_PAR
    SF_IS_INF
    share_hek_hek
    sharepvn
    SHARP_S_SKIP
    SH_PATH
    SHUTDOWN_TERM
    sI
    SIMPLE
    Simple_vFAIL
    Simple_vFAILn
    SINGLE_PAT_MOD
    SIPHASH_SEED_STATE
    SIPROUND
    S_IWOTH
    S_IXOTH
    Size_t_MAX
    SKIP_IF_CHAR
    SLOPPYDIVIDE
    SOCKET_OPEN_MODE
    S_PAT_MODS
    specialWARN
    SS_ACCVIO
    SS_ADD_BOOL
    SS_ADD_DPTR
    SS_ADD_DXPTR
    SS_ADD_END
    SS_ADD_INT
    SS_ADD_IV
    SS_ADD_LONG
    SS_ADD_PTR
    SS_ADD_UV
    SS_BUFFEROVF
    ssc_add_cp
    SSCHECK
    ssc_init_zero
    ssc_match_all_cp
    SS_DEVOFFLINE
    SSGROW
    SS_IVCHAN
    SSize_t_MAX
    SS_MAXPUSH
    SS_NOPRIV
    SS_NORMAL
    SSPOPBOOL
    SSPOPDPTR
    SSPOPDXPTR
    SSPOPINT
    SSPOPIV
    SSPOPLONG
    SSPOPPTR
    SSPOPUV
    SSPUSHBOOL
    SSPUSHDPTR
    SSPUSHDXPTR
    SSPUSHINT
    SSPUSHIV
    SSPUSHLONG
    SSPUSHPTR
    SSPUSHUV
    Stack_off_t_MAX
    STANDARD_C
    StashHANDLER
    Stat
    STATIC
    Stat_t
    STATUS_ALL_FAILURE
    STATUS_ALL_SUCCESS
    STATUS_CURRENT
    STATUS_EXIT
    STATUS_EXIT_SET
    STATUS_NATIVE
    STATUS_NATIVE_CHILD_SET
    STATUS_UNIX
    STATUS_UNIX_EXIT_SET
    STATUS_UNIX_SET
    STD_PAT_MODS
    STD_PMMOD_FLAGS_CLEAR
    STORE_LC_NUMERIC_SET_STANDARD
    strBEGINs
    Strerror
    STRFMON_LOCK
    STRFMON_UNLOCK
    STRFTIME_LOCK
    STRFTIME_UNLOCK
    STRUCT_OFFSET
    STRUCT_SV
    SUBVERSION
    sv_2bool_nomg
    sv_2nv
    sv_2pv_nomg
    SvANY
    SvARENA_CHAIN
    SvARENA_CHAIN_SET
    SvCANCOW
    SvCANEXISTDELETE
    sv_cathek
    sv_catpvn_nomg_utf8_upgrade
    SvCOMPILED
    SvCOMPILED_off
    SvCOMPILED_on
    SV_CONST_RETURN
    SV_CONSTS_COUNT
    SV_COW_OTHER_PVS
    SV_COW_REFCNT_MAX
    SV_COW_SHARED_HASH_KEYS
    SvDESTROYABLE
    SV_DO_COW_SVSETSV
    SvEND_set
    SvENDx
    SVf256
    SVf32
    SvFAKE
    SvFAKE_off
    SvFAKE_on
    SVf_AMAGIC
    SVf_BREAK
    SVf_FAKE
    SVf_IOK
    SVf_IsCOW
    SVf_IVisUV
    SvFLAGS
    SVf_NOK
    SVf_OK
    SVf_OOK
    SVf_POK
    SVf_PROTECT
    SVf_READONLY
    SVf_ROK
    SVf_THINKFIRST
    SvGMAGICAL_off
    SvGMAGICAL_on
    Sv_Grow
    SvGROW_mutable
    SvIMMORTAL
    SvIMMORTAL_INTERP
    SvIMMORTAL_TRUE
    SvIOK_nog
    SvIOK_nogthink
    SvIOKp_on
    SvIsCOW_off
    SvIsCOW_on
    SvIsCOW_static
    SvIS_FREED
    SvIsUV
    SvIsUV_off
    SvIsUV_on
    SvIV_please
    SvIV_please_nomg
    SvIVXx
    SvLENx
    SvMAGIC
    SvMAGICAL_off
    SvMAGICAL_on
    SV_MUTABLE_RETURN
    SvNIOK_nog
    SvNIOK_nogthink
    SvNOK_nog
    SvNOK_nogthink
    SvNOKp_on
    SvNVXx
    SvOBJECT
    SvOBJECT_off
    SvOBJECT_on
    SvOK_off
    SvOK_off_exc_UV
    SvOKp
    SvOOK_on
    SvOURSTASH
    SvOURSTASH_set
    SvPADMY
    SvPADMY_on
    SvPAD_OUR
    SVpad_OUR
    SvPAD_OUR_on
    SvPADSTALE
    SvPADSTALE_off
    SvPADSTALE_on
    SvPAD_STATE
    SVpad_STATE
    SvPAD_STATE_on
    SvPADTMP
    SvPADTMP_off
    SvPADTMP_on
    SvPAD_TYPED
    SVpad_TYPED
    SvPAD_TYPED_on
    SVpav_REAL
    SVpav_REIFY
    SvPCS_IMPORTED
    SvPCS_IMPORTED_off
    SvPCS_IMPORTED_on
    SvPEEK
    SVpgv_GP
    SVphv_CLONEABLE
    SVphv_HasAUX
    SVphv_HASKFLAGS
    SVphv_LAZYDEL
    SVphv_SHAREKEYS
    SVp_IOK
    SVp_NOK
    SvPOK_byte_nog
    SvPOK_byte_nogthink
    SvPOK_byte_pure_nogthink
    SvPOK_nog
    SvPOK_nogthink
    SvPOK_or_cached_IV
    SvPOKp_on
    SvPOK_pure_nogthink
    SvPOK_utf8_nog
    SvPOK_utf8_nogthink
    SvPOK_utf8_pure_nogthink
    SV_POSBYTES
    SVp_POK
    SVppv_STATIC
    SVprv_PCS_IMPORTED
    SVprv_WEAKREF
    SVp_SCREAM
    SvPV_flags_const_nolen
    sv_pvn_force_nomg
    SvREFCNT_IMMORTAL
    SvRMAGICAL_off
    SvRMAGICAL_on
    SvRV_const
    SvSCREAM
    SvSCREAM_off
    SvSCREAM_on
    SvSetSV_and
    SvSetSV_nosteal_and
    SVs_GMG
    SvSHARED_HEK_FROM_PV
    SvSMAGICAL_off
    SvSMAGICAL_on
    SVs_OBJECT
    SVs_RMG
    SVs_SMG
    SvTAIL
    SvTEMP
    SvTEMP_off
    SvTEMP_on
    SvTHINKFIRST
    SvTIED_mg
    SVt_MASK
    SVt_PVBM
    SvTRUEx_nomg
    SVt_RV
    SVTYPEMASK
    SV_UNDEF_RETURNS_NULL
    SvUOK_nog
    SvUOK_nogthink
    SvVALID
    SvWEAKREF
    SvWEAKREF_off
    SvWEAKREF_on
    SWITCHSTACK
    SYSTEM_GMTIME_MAX
    SYSTEM_GMTIME_MIN
    SYSTEM_LOCALTIME_MAX
    SYSTEM_LOCALTIME_MIN
    TARGi
    TARGn
    TARGu
    tC
    THR
    THREAD_CREATE_NEEDS_STACK
    THREAD_RET_TYPE
    tI
    toFOLD_LC
    toFOLD_uni
    toLOWER_uni
    TOO_LATE_FOR
    TOO_NAUGHTY
    TO_OUTPUT_WARNINGS
    TOPi
    TOPl
    TOPm1s
    TOPMARK
    TOPn
    to_posix_FOLD
    to_posix_LOWER
    to_posix_UPPER
    TOPp
    TOPp1s
    TOPpx
    TOPu
    TOPul
    toTITLE_uni
    toU8_FOLD_LC
    toU8_LOWER_LC
    toU8_UPPER_LC
    toUPPER_LATIN1_MOD
    toUPPER_LC
    toUPPER_uni
    toUSE_UNI_CHARSET_NOT_DEPENDS
    TRIE_STCLASS
    TRIE_STUDY_OPT
    TRUE
    TRYAGAIN
    tryAMAGICbin_MG
    tryAMAGICunDEREF
    tryAMAGICun_MG
    TS_W32_BROKEN_LOCALECONV
    tTHX
    TURN_OFF_WARNINGS_IN_SUBSTITUTE_PARSE
    TWO_BYTE_UTF8_TO_NATIVE
    TWO_BYTE_UTF8_TO_UNI
    TYPE_CHARS
    TYPE_DIGITS
    TZSET_LOCK
    TZSET_UNLOCK
    U16_MAX
    U16_MIN
    U32_MAX
    U32_MAX_P1
    U32_MAX_P1_HALF
    U32_MIN
    U8_MAX
    U8_MIN
    U8TO16_LE
    U8TO32_LE
    U8TO64_LE
    U_I
    U_L
    UNICODE_ALLOW_ANY
    UNICODE_ALLOW_SUPER
    UNICODE_ALLOW_SURROGATE
    UNICODE_BYTE_ORDER_MARK
    UNICODE_DOT_DOT_VERSION
    UNICODE_DOT_VERSION
    UNICODE_GREEK_CAPITAL_LETTER_SIGMA
    UNICODE_GREEK_SMALL_LETTER_FINAL_SIGMA
    UNICODE_GREEK_SMALL_LETTER_SIGMA
    UNICODE_IS_32_CONTIGUOUS_NONCHARS
    UNICODE_IS_BYTE_ORDER_MARK
    UNICODE_IS_END_PLANE_NONCHAR_GIVEN_NOT_SUPER
    UNICODE_IS_NONCHAR_GIVEN_NOT_SUPER
    UNICODE_MAJOR_VERSION
    UNICODE_PAT_MOD
    UNICODE_PAT_MODS
    UNICODE_SURROGATE_FIRST
    UNICODE_SURROGATE_LAST
    UNI_IS_INVARIANT
    UNI_SEMANTICS
    UNISKIP
    UNKNOWN_ERRNO_MSG
    UNLINK
    UNLOCK_DOLLARZERO_MUTEX
    UNLOCK_LC_NUMERIC_STANDARD
    UNOP_AUX_item_sv
    unpackWARN1
    unpackWARN2
    unpackWARN3
    unpackWARN4
    UPDATE_WARNINGS_LOC
    UPG_VERSION
    uproot_SV
    U_S
    USE_BSDPGRP
    USE_ENVIRON_ARRAY
    USE_GRENT_BUFFER
    USE_GRENT_FPTR
    USE_GRENT_PTR
    USE_HASH_SEED
    USE_HOSTENT_BUFFER
    USE_HOSTENT_ERRNO
    USE_HOSTENT_PTR
    USE_LEFT
    USE_LOCALE
    USE_LOCALE_ADDRESS
    USE_LOCALE_COLLATE
    USE_LOCALE_CTYPE
    USE_LOCALE_IDENTIFICATION
    USE_LOCALE_MEASUREMENT
    USE_LOCALE_MESSAGES
    USE_LOCALE_MONETARY
    USE_LOCALE_NAME
    USE_LOCALE_NUMERIC
    USE_LOCALE_PAPER
    USE_LOCALE_SYNTAX
    USE_LOCALE_TELEPHONE
    USE_LOCALE_THREADS
    USE_LOCALE_TIME
    USE_LOCALE_TOD
    USEMYBINMODE
    USE_NETENT_BUFFER
    USE_NETENT_ERRNO
    USE_NETENT_PTR
    USE_PL_CUR_LC_ALL
    USE_PL_CURLOCALES
    USE_POSIX_2008_LOCALE
    USE_PROTOENT_BUFFER
    USE_PROTOENT_PTR
    USE_PWENT_BUFFER
    USE_PWENT_FPTR
    USE_PWENT_PTR
    USE_QUERYLOCALE
    USE_REENTRANT_API
    USER_PROP_MUTEX_INIT
    USER_PROP_MUTEX_LOCK
    USER_PROP_MUTEX_TERM
    USER_PROP_MUTEX_UNLOCK
    USE_SERVENT_BUFFER
    USE_SERVENT_PTR
    USE_SPENT_BUFFER
    USE_SPENT_PTR
    USE_STAT_RDEV
    USE_SYSTEM_GMTIME
    USE_SYSTEM_LOCALTIME
    USE_THREAD_SAFE_LOCALE
    USE_TM64
    USE_UTF8_IN_NAMES
    UTF
    UTF8_ACCUMULATE
    UTF8_ALLOW_ANYUV
    UTF8_ALLOW_DEFAULT
    UTF8_ALLOW_FE_FF
    UTF8_ALLOW_FFFF
    UTF8_ALLOW_LONG_AND_ITS_VALUE
    UTF8_ALLOW_SURROGATE
    UTF8_DISALLOW_ABOVE_31_BIT
    UTF8_DISALLOW_FE_FF
    UTF8_EIGHT_BIT_HI
    UTF8_EIGHT_BIT_LO
    UTF8_GOT_ABOVE_31_BIT
    UTF8_GOT_LONG_WITH_VALUE
    UTF8_IS_ABOVE_LATIN1
    UTF8_IS_ABOVE_LATIN1_START
    UTF8_IS_CONTINUATION
    UTF8_IS_CONTINUED
    UTF8_IS_DOWNGRADEABLE_START
    UTF8_IS_NEXT_CHAR_DOWNGRADEABLE
    UTF8_IS_NONCHAR_GIVEN_THAT_NON_SUPER_AND_GE_PROBLEMATIC
    UTF8_IS_START
    UTF8_IS_START_base
    UTF8_MAX_FOLD_CHAR_EXPAND
    UTF8_MAXLEN
    UTF8_MIN_CONTINUATION_BYTE
    utf8_to_utf16
    utf8_to_utf16_reversed
    UTF8_TWO_BYTE_HI
    UTF8_TWO_BYTE_HI_nocast
    UTF8_TWO_BYTE_LO
    UTF8_TWO_BYTE_LO_nocast
    UTF8_WARN_ABOVE_31_BIT
    UTF8_WARN_FE_FF
    UTF_ACCUMULATION_SHIFT
    UTF_CONTINUATION_BYTE_INFO_BITS
    UTF_CONTINUATION_MARK
    UTF_CONTINUATION_MASK
    UTF_EBCDIC_CONTINUATION_BYTE_INFO_BITS
    UTF_FIRST_CONT_BYTE
    UTF_IS_CONTINUATION_MASK
    UTF_MIN_ABOVE_LATIN1_BYTE
    UTF_MIN_CONTINUATION_BYTE
    UTF_MIN_START_BYTE
    UTF_START_BYTE
    UTF_START_MARK
    UTF_START_MASK
    UTF_TO_NATIVE
    UV_MAX_P1
    UV_MAX_P1_HALF
    VCMP
    vFAIL
    vFAIL2
    vFAIL2utf8f
    vFAIL3
    vFAIL3utf8f
    vFAIL4
    VNORMAL
    VNUMIFY
    VOL
    VSTRINGIFY
    vTHX
    VT_NATIVE
    vtohl
    vtohs
    VTYPECHECK
    VUTIL_REPLACE_CORE
    VVERIFY
    vWARN
    vWARN3
    vWARN4
    vWARN5
    vWARN_dep
    VXS
    VXS_CLASS
    VXSp
    VXS_RETURN_M_SV
    VXSXSDP
    want_vtbl_bm
    want_vtbl_fm
    WARN_ALLstring
    WARN_DEFAULTstring
    WARN_NONEstring
    warn_non_literal_string
    WARNshift
    WARNsize
    what_MULTI_CHAR_FOLD_latin1_safe
    what_MULTI_CHAR_FOLD_utf8_safe
    WIN32SCK_IS_STDSCK
    withinCOUNT
    WORTH_PER_WORD_LOOP
    WORTH_PER_WORD_LOOP_BINMODE
    WSETLOCALE_LOCK
    WSETLOCALE_UNLOCK
    XDIGIT_VALUE
    xI
    xio_any
    xio_dirp
    xI_offset
    xiv_iv
    xlv_targoff
    XOPd_xop_class
    XOPd_xop_desc
    XOPd_xop_dump
    XOPd_xop_name
    XOPd_xop_peep
    XOPf_xop_class
    XOPf_xop_desc
    XOPf_xop_dump
    XOPf_xop_name
    XOPf_xop_peep
    XORSHIFT128_set
    XPUSHTARG
    XPUSHundef
    xpv_len
    XS_DYNAMIC_FILENAME
    XS_INTERNAL
    XTENDED_PAT_MOD
    xuv_uv
    xV_FROM_REF
    YIELD
    YYEMPTY
    YYSTYPE_IS_DECLARED
    YYSTYPE_IS_TRIVIAL
    ZAPHOD32_FINALIZE
    ZAPHOD32_MIX
    ZAPHOD32_SCRAMBLE32
    ZAPHOD32_STATIC_INLINE
    ZAPHOD32_WARN2
    ZAPHOD32_WARN3
    ZAPHOD32_WARN4
    ZAPHOD32_WARN5
    ZAPHOD32_WARN6
    aTHXo_
    aTHXx_
    BASE_TWO_BYTE_HI_
    BASE_TWO_BYTE_LO_
    CC_ALPHA_
    CC_ALPHANUMERIC_
    CC_ASCII_
    CC_BINDIGIT_
    CC_BLANK_
    CC_CASED_
    CC_CHARNAME_CONT_
    CC_CNTRL_
    CC_DIGIT_
    CC_GRAPH_
    CC_IDFIRST_
    CC_IS_IN_SOME_FOLD_
    CC_LOWER_
    CC_mask_A_
    CC_MNEMONIC_CNTRL_
    CC_NON_FINAL_FOLD_
    CC_NONLATIN1_FOLD_
    CC_NONLATIN1_SIMPLE_FOLD_
    CC_OCTDIGIT_
    CC_PRINT_
    CC_PUNCT_
    CC_QUOTEMETA_
    CC_SPACE_
    CC_UPPER_
    CC_VERTSPACE_
    CC_WORDCHAR_
    CC_XDIGIT_
    CHECK_AND_OUTPUT_WIDE_LOCALE_CP_MSG_
    CHECK_AND_OUTPUT_WIDE_LOCALE_UTF8_MSG_
    CHECK_AND_WARN_PROBLEMATIC_LOCALE_
    CHECK_MALLOC_TOO_LATE_FOR_
    DEBUG_LOCALE_INITIALIZATION_
    DFA_RETURN_FAILURE_
    DFA_RETURN_SUCCESS_
    DFA_TEASE_APART_FF_
    FUNCTION__
    generic_func_utf8_safe_
    generic_invlist_utf8_safe_
    generic_invlist_uvchr_
    generic_isCC_
    generic_isCC_A_
    generic_LC_
    generic_LC_base_
    generic_LC_func_utf8_safe_
    generic_LC_invlist_utf8_safe_
    generic_LC_invlist_uvchr_
    generic_LC_non_invlist_utf8_safe_
    generic_LC_utf8_safe_
    generic_LC_uvchr_
    generic_non_invlist_utf8_safe_
    generic_utf8_safe_
    generic_utf8_safe_no_upper_latin1_
    generic_uvchr_
    HAS_IGNORED_LOCALE_CATEGORIES_
    HIGHEST_REGCOMP_DOT_H_SYNC_
    inRANGE_helper_
    is_MULTI_CHAR_FOLD_utf8_safe_part0_
    is_MULTI_CHAR_FOLD_utf8_safe_part1_
    is_MULTI_CHAR_FOLD_utf8_safe_part2_
    is_MULTI_CHAR_FOLD_utf8_safe_part3_
    KEY___CLASS__
    KEY___DATA__
    KEY___END__
    KEY___FILE__
    KEY___LINE__
    KEY___PACKAGE__
    KEY___SUB__
    LC_ADDRESS_AVAIL_
    LC_COLLATE_AVAIL_
    LC_CTYPE_AVAIL_
    LC_IDENTIFICATION_AVAIL_
    LC_MEASUREMENT_AVAIL_
    LC_MESSAGES_AVAIL_
    LC_MONETARY_AVAIL_
    LC_NAME_AVAIL_
    LC_NUMERIC_AVAIL_
    LC_PAPER_AVAIL_
    LC_SYNTAX_AVAIL_
    LC_TELEPHONE_AVAIL_
    LC_TIME_AVAIL_
    LC_TOD_AVAIL_
    LOCALE_CATEGORIES_COUNT_
    LOCALE_LOCK_
    LOCALE_LOCK_DOES_SOMETHING_
    locale_panic_
    locale_panic_via_
    LOCALE_TERM_POSIX_2008_
    LOCALE_UNLOCK_
    lsbit_pos_uintmax_
    LZC_TO_MSBIT_POS_
    MBLEN_LOCK_
    MBLEN_UNLOCK_
    MBRLEN_LOCK_
    MBRLEN_UNLOCK_
    MBRTOWC_LOCK_
    MBRTOWC_UNLOCK_
    MBTOWC_LOCK_
    MBTOWC_UNLOCK_
    MEM_WRAP_CHECK_
    msbit_pos_uintmax_
    NOT_IN_NUMERIC_STANDARD_
    NOT_IN_NUMERIC_UNDERLYING_
    o1_
    OFFUNISKIP_helper_
    __PATCHLEVEL_H_INCLUDED__
    PLATFORM_SYS_INIT_
    PLATFORM_SYS_TERM_
    pTHXo_
    pTHX__VALUE_
    pTHX_VALUE_
    pTHXx_
    SAFE_FUNCTION__
    SBOX32_CASE_
    SVf_
    TOO_LATE_FOR_
    type1_
    UNISKIP_BY_MSB_
    UTF8_IS_SUPER_NO_CHECK_
    UTF8_NO_CONFIDENCE_IN_CURLEN_
    utf8_safe_assert_
    UTF_FIRST_CONT_BYTE_110000_
    UTF_START_BYTE_110000_
    WCRTOMB_LOCK_
    WCRTOMB_UNLOCK_
    WCTOMB_LOCK_
    WCTOMB_UNLOCK_
    what_MULTI_CHAR_FOLD_utf8_safe_part0_
    what_MULTI_CHAR_FOLD_utf8_safe_part1_
    what_MULTI_CHAR_FOLD_utf8_safe_part2_
    what_MULTI_CHAR_FOLD_utf8_safe_part3_
    what_MULTI_CHAR_FOLD_utf8_safe_part4_
    what_MULTI_CHAR_FOLD_utf8_safe_part5_
    what_MULTI_CHAR_FOLD_utf8_safe_part6_
    what_MULTI_CHAR_FOLD_utf8_safe_part7_
    withinCOUNT_KNOWN_VALID_
    WRAP_U8_LC_
    XPVCV_COMMON_
    XPV_HEAD_
);

# This is a list of symbols that are used by the OS and which perl may need to
# define or redefine, and which aren't otherwise currently detectable by this
# program's algorithms as being such.  They are not namespace pollutants
my @system_symbols = qw(
    environ
    htonl
    htons
    isnormal
    INT32_MIN
    INT64_MIN
    LDBL_DIG
    ntohl
    ntohs
    O_CREAT
    O_RDWR
    O_WRONLY
    pthread_attr_init
    pthread_create
    setregid
    setreuid
    socketpair
    S_IWGRP
    S_IWUSR
    S_IXGRP
    S_IXUSR
    __setfdccsid
    __attribute__format__null_ok__
);

# This is a list of symbols that are needed by the ext/re module, and are not
# documented.  They become undefined for any other modules.
my @needed_by_ext_re = qw(
    FAIL_
    first_upper_bit_set_byte_number
    invlist_intersection_complement_2nd_
    invlist_union_complement_2nd_
    PARSE_IDENT_ERROR_POSITION
    PARSE_IDENT_ERROR_TEXT
    RExC_parse_advance
    WARN_HELPER_
);

# This is a list of symbols that are needed by various ext/ modules, and are
# not documented.  They become undefined for any other modules.
my @needed_by_ext = qw(
    OPpPARAM_IF_FALSE
    OPpPARAM_IF_UNDEF
    OPpSELF_IN_PAD
);

# This is a list of symbols that are needed to be visible everywhere and are
# not documented, and we don't plan to document them any time soon.
# Effectively these are symbols that would otherwise be in
# @unresolved_visibility_overrides, but we have resolved them to here.
#
# Think twice about adding a symbol to this list.  Would it be better to
# instead document the symbol?  Or maybe its name could easily be changed to
# match $names_reserved_for_perl_use_re?
#
# Typically these are symbols that are behind-the-scenes helpers whose use is
# obvious from inspection of the things they help.
#
# The list has two parts, separated by a blank line.  The names in the second
# part have a trailing underscore, indicating the intent for this symbol to
# not be directly usable by XS code
my @undocumented_always_visible = qw(
    DEBUG_A
    DEBUG_A_FLAG
    DEBUG_A_TEST
    DEBUG_B
    DEBUG_B_FLAG
    DEBUG_B_TEST
    DEBUG_c
    DEBUG_C
    DEBUG_c_FLAG
    DEBUG_C_FLAG
    DEBUG_c_TEST
    DEBUG_C_TEST
    DEBUG_D
    DEBUG_D_FLAG
    DEBUG_D_TEST
    DEBUG_f
    DEBUG_f_FLAG
    DEBUG_f_TEST
    DEBUG_h_FLAG
    DEBUG_h_TEST
    DEBUG_i
    DEBUG_i_FLAG
    DEBUG_i_TEST
    DEBUG_J_FLAG
    DEBUG_J_TEST
    DEBUG_l
    DEBUG_L
    DEBUG_l_FLAG
    DEBUG_L_FLAG
    DEBUG_l_TEST
    DEBUG_L_TEST
    DEBUG_Lv
    DEBUG_Lv_TEST
    DEBUG_m
    DEBUG_M
    DEBUG_m_FLAG
    DEBUG_M_FLAG
    DEBUG_m_TEST
    DEBUG_M_TEST
    DEBUG_o
    DEBUG_o_FLAG
    DEBUG_o_TEST
    DEBUG_p
    DEBUG_P
    DEBUG_p_FLAG
    DEBUG_P_FLAG
    DEBUG_p_TEST
    DEBUG_P_TEST
    DEBUG_Pv
    DEBUG_Pv_TEST
    DEBUG_q
    DEBUG_q_FLAG
    DEBUG_q_TEST
    DEBUG_r
    DEBUG_R
    DEBUG_r_FLAG
    DEBUG_R_FLAG
    DEBUG_r_TEST
    DEBUG_R_TEST
    DEBUG_s
    DEBUG_S
    DEBUG_s_FLAG
    DEBUG_S_FLAG
    DEBUG_s_TEST
    DEBUG_S_TEST
    DEBUG_t
    DEBUG_T
    DEBUG_t_FLAG
    DEBUG_T_FLAG
    DEBUG_t_TEST
    DEBUG_T_TEST
    DEBUG_u
    DEBUG_U
    DEBUG_u_FLAG
    DEBUG_U_FLAG
    DEBUG_u_TEST
    DEBUG_U_TEST
    DEBUG_Uv
    DEBUG_Uv_TEST
    DEBUG_v
    DEBUG_v_FLAG
    DEBUG_v_TEST
    DEBUG_x
    DEBUG_X
    DEBUG_x_FLAG
    DEBUG_X_FLAG
    DEBUG_x_TEST
    DEBUG_X_TEST
    DEBUG_Xv
    DEBUG_Xv_TEST
    DEBUG_y
    DEBUG_y_FLAG
    DEBUG_y_TEST
    DEBUG_yv
    DEBUG_yv_TEST
    MAX_UNICODE_UTF8_BYTES

    assert_scalar_or_IO_
    DEBUG__
    DEBUG_A_TEST_
    DEBUG_BOTH_FLAGS_TEST_
    DEBUG_B_TEST_
    DEBUG_c_TEST_
    DEBUG_C_TEST_
    DEBUG_D_TEST_
    DEBUG_f_TEST_
    DEBUG_h_TEST_
    DEBUG_i_TEST_
    DEBUG_J_TEST_
    DEBUG_l_TEST_
    DEBUG_L_TEST_
    DEBUG_Lv_TEST_
    DEBUG_m_TEST_
    DEBUG_M_TEST_
    DEBUG_o_TEST_
    DEBUG_p_TEST_
    DEBUG_P_TEST_
    DEBUG_Pv_TEST_
    DEBUG_q_TEST_
    DEBUG_r_TEST_
    DEBUG_R_TEST_
    DEBUG_s_TEST_
    DEBUG_S_TEST_
    DEBUG_t_TEST_
    DEBUG_T_TEST_
    DEBUG_u_TEST_
    DEBUG_U_TEST_
    DEBUG_Uv_TEST_
    DEBUG_v_TEST_
    DEBUG_x_TEST_
    DEBUG_X_TEST_
    DEBUG_Xv_TEST_
    DEBUG_y_TEST_
    DEBUG_yv_TEST_
    EXTEND_NEEDS_GROW_
    EXTEND_SAFE_N_
    MEM_WRAP_NEEDS_RUNTIME_CHECK_
    MEM_WRAP_WILL_WRAP_
    NV_BODYLESS_UNION_
    RXf_PMf_CHARSET_SHIFT_
    RXf_PMf_SHIFT_COMPILETIME_
    RXf_PMf_SHIFT_NEXT_
    shifted_octet_
    STATIC_ASSERT_STRUCT_BODY_
    STATIC_ASSERT_STRUCT_NAME_
    SV_HEAD_DEBUG_
    toFOLD_utf8_flags_
    toLOWER_utf8_flags_
    toTITLE_utf8_flags_
    toUPPER_utf8_flags_
    UTF8_CHECK_ONLY_BIT_POS_
    UTF8_DIE_IF_MALFORMED_BIT_POS_
    UTF8_FORCE_WARN_IF_MALFORMED_BIT_POS_
    UTF8_GOT_CONTINUATION_BIT_POS_
    UTF8_GOT_EMPTY_BIT_POS_
    UTF8_GOT_LONG_BIT_POS_
    UTF8_GOT_LONG_WITH_VALUE_BIT_POS_
    UTF8_GOT_NONCHAR_BIT_POS_
    UTF8_GOT_NON_CONTINUATION_BIT_POS_
    UTF8_GOT_OVERFLOW_BIT_POS_
    UTF8_GOT_SHORT_BIT_POS_
    UTF8_GOT_SUPER_BIT_POS_
    UTF8_GOT_SURROGATE_BIT_POS_
    UTF8_NO_CONFIDENCE_IN_CURLEN_BIT_POS_
    UTF8_WARN_NONCHAR_BIT_POS_
    UTF8_WARN_SUPER_BIT_POS_
    UTF8_WARN_SURROGATE_BIT_POS_
);

# Turn all the lists above into hashes
my %unresolved_visibility_overrides;
$unresolved_visibility_overrides{$_} = 1 for @unresolved_visibility_overrides;

my %system_symbols;
$system_symbols{$_} = 1 for @system_symbols;

my %needed_by_ext_re;
$needed_by_ext_re{$_} = 1 for @needed_by_ext_re;

my %needed_by_ext;
$needed_by_ext{$_} = 1 for @needed_by_ext;

my %undocumented_always_visible;
$undocumented_always_visible{$_} = 1 for @undocumented_always_visible;

# Keep lists of symbols to undef under various conditions.  We can initialize
# the two ones for perl extensions with the lists above.
my %always_undefs;
my %non_ext_re_undefs = %needed_by_ext_re;
my %non_ext_undefs = %needed_by_ext;

# List of macros that need a "Perl_" synonym generated for them
my %need_longs;

# Create lists of headers and C files to examine.  Use all top level .c files,
# and all top level .h files that aren't on the $skip_files list.
my @header_list;
my @c_list;
open my $mf, "<", "MANIFEST" or die "Can't open MANIFEST: $!";
while (defined (my $file = <$mf>)) {
    chomp $file;;
    $file =~ s/ \s .* //x;
    next if $file =~ m,/,;
    next if defined $skip_files{$file};

    push @header_list, $file if $file =~ / ( \.h | \.inc ) \b /x;
    push @c_list, $file if $file =~ / \.c \b /x;
}
close $mf or die "Can't close MANIFEST: $!";

# One part of this program is to keep macros from being externally visible
# that shouldn't be.  This is done by adding #undef's to embed.h for the ones
# that should be hidden.  Documented symbols have their desired visibility
# specified in their documentation.  Undocumented ones are presumed here to
# need to be hidden, unless overriden by one of the lists above.
#
# Only macros defined in a header can be visible externally. This is done by
# the XS code #including perl.h which in turn #includes a bunch of headers,
# which the code just above placed in @header_list.  The reason we look at C
# files is to find documentation that will announce the symbol's intended
# visibility.
#
# But just because there is a #define for a given symbol in a header doesn't
# mean it actually gets defined.  That definition may be in the scope of some
# #ifdef's that cause the definition to be skipped.  Some of those #ifdefs are
# dependent on Configure options and/or the platform being used.  We have to
# assume for those that they indicate that the definition does happen.  But
# we know the values for some others, and we can use those to rule in or out
# whether or not a definition happens.  The simplist example is
#   #ifdef PERL_CORE ... #endif
# Any #define within the '...' won't be visible to code outside the core, so
# doesn't need an #undef generated for it.  No harm would be done to add a
# #undef for such symbols, except for the unnecessary noise.  And there are so
# many of them that the noise would be considerable,  so this program
# examines those #ifdef's, and if they indicate a symbol isn't visible outside
# its intended target, no #undef gets added to embed.h.
#
# One type of such #ifdef follows the convention in perl's source code that a
# C file, 'foo.c', will #define a symbol at the beginning named PERL_IN_FOO_C.
# And some otherwise global symbols in header files will be protected from
# being visible from outside foo.c by
#   #ifdef PERL_IN_FOO_C
#   #  define x
#   #  define y
#   #    ...
#   #endif
#
# 'x', 'y', ... need not be #undef'ed, as they aren't visible outside the
# C files that are permitted to see them.
#
# This hash contains the base constraints.  0 means the symbol is to be
# considered undefined; 1, defined.
my %cpp_ifdef_constraints;

# The regular expression engine has complications beyond the above, mainly due
# to the fact that it appears as both core and as an extension, via 'use re'.
# So, for it alone, some #defines that would normally be excluded by the
# PERL_IN_FOO_C convention are visible to the 'use re' extension.  There are
# also several other #ifdef symbols it uses.  The list, current as of this
# writing, is:
my @regex_conditions = qw(
                           PERL_IN_DQUOTE_C
                           PERL_IN_REGCOMP_C
                           PERL_IN_REGCOMP_DEBUG_C
                           PERL_IN_REGCOMP_INVLIST_C
                           PERL_IN_REGCOMP_STUDY_C
                           PERL_IN_REGCOMP_TRIE_C
                           PERL_IN_REGEXEC_C

                           PERL_IN_REGCOMP_ANY
                           PERL_EXT_RE_BUILD
                           PERL_IN_REGEX_ENGINE
                           PLUGGABLE_RE_EXTENSION
                         );
# None of those symbols will be defined when not in the 'use re extension' nor
# core.
my (%in_regex, %not_in_regex);
$in_regex{$_}     = 1 for @regex_conditions;
$not_in_regex{$_} = 0 for @regex_conditions;

# Generate the symbols for the PERL_IN_FOO_C convention, excluding those from
# the 'use re' we've already specially handled.  Otherwise, the convention
# means each can be set to 0, as being outside of core contradicts all the
# non-regex ones.
for my $c (@c_list) {
    my $c_prime = $c =~ s/[.]/_/r;
    $c_prime = "PERL_IN_\U$c_prime";
    next if defined $in_regex{$c_prime};
    $cpp_ifdef_constraints{$c_prime} = 0;
}

# This doesn't follow the convention, as the file name is different from this
$cpp_ifdef_constraints{PERL_IN_MRO_C} = 0;

# Besides the obvious PERL_CORE, an inspection of our source revealed the
# following symbols that won't be defined for general XS code.
$cpp_ifdef_constraints{PERL_CORE} = 0;
$cpp_ifdef_constraints{PERL_IN_XS_APITEST} = 0;
$cpp_ifdef_constraints{PERL_DEBUG_READONLY_OPS} = 0;
$cpp_ifdef_constraints{PERL_DEBUG_DUMPUNTIL} = 0;
$cpp_ifdef_constraints{PERL_ENABLE_EXPERIMENTAL_REGEX_OPTIMISATIONS} = 0;
$cpp_ifdef_constraints{EXPERIMENTAL_INPLACESCAN} = 0;

# Appears to be obsolete; App:s2p, etc were created to handle this
# functionality
$cpp_ifdef_constraints{PERL_FOR_X2P} = 0;

# This is used only for perl core development, and no module should ever have
# it defined.
$cpp_ifdef_constraints{WIN32_USE_FAKE_OLD_MINGW_LOCALES} = 0;

$cpp_ifdef_constraints{PERL_EXT} = 0;
$cpp_ifdef_constraints{PERL_EXT_RE_BUILD} = 0;

# This program evaluates the conditionals surrounding every #define in every
# examined header.  It turns out that in many cases, using the constraints in
# %cpp_ifdef_constraints, a conditional can be reduced to a plain 0 or 1.  In
# those cases, we know immediately if the #defined symbol is externally
# visible.  In other cases, there are other terms in the conditionals whose
# values we don't know; they typically depend on the platform and Configure
# options being used.  Hence, there are circumstances where the symbol does
# get #defined, and is externally visible, so we will add an #undef for it if
# it shouldn't be visible.  There is no harm in undefining a symol that
# doesn't happen to get defined in this particular build environment.
#
# Perl has modules that are considered extensions to the core, and are granted
# access to functionality and symbols that are denied others.  The C
# preprocessor symbol PERL_EXT is defined for these, and often there are
# conditionals like
#   #if defined(PERL_CORE) || defined(PERL_EXT)
# in our headers.  So, in spite of PERL_CORE not being defined, the extension
# does have access to the symbols defined within that conditional's scope.
# The regular expression engine module is so important that it has additional
# conditionals that are #defined just for it.  Many symbols that it needs are
# of no use to other extensions, so shouldn't be visible to those others.
# Below we extend the basic %cpp_ifdef_constraints to three cases:
#   %cpp_always_externally_visible
#           are symbols that don't depend on the module being considered an
#           extension.  They may not actually be visible on a particular
#           platform and build options, but theoretically there is a
#           combination where they are visible, so we treat them as always
#           visible.
#   %cpp_visible_to_regex_extension
#           are symbols that are visible to the regular expression extension
#           (the one enabled by 'use re'), but no other extensions.  That is
#           they are the symbols that match %cpp_always_externally_visible
#           plus the ones visible to the re extension
#   %%cpp_visible_to_extensions
#           are symbols that are visible to all other extensions, but not to
#           non-extension modules

my %cpp_always_externally_visible =  (
                                       %cpp_ifdef_constraints,
                                       %not_in_regex,
                                       PERL_EXT               => 0,
                                     );
my %cpp_visible_to_regex_extension = (
                                       %cpp_ifdef_constraints,
                                       %in_regex,
                                       PERL_EXT               => 0,
                                     );
my %cpp_visible_to_extensions      = (
                                       %cpp_ifdef_constraints,
                                       %not_in_regex,
                                       PERL_EXT               => 1,
                                     );

# Create mnemonic single-character codes for these
my %visibility_types = (
                          1 =>  \%cpp_always_externally_visible,
                         '/' => \%cpp_visible_to_regex_extension,
                         'E' => \%cpp_visible_to_extensions,
                       );

my @az = ('a'..'z');
my $never_visible_flags= "eX";
my $never_visible_flags_re = qr/[$never_visible_flags]/;

my $visible_everywhere_flags = "AC";
my $visible_everywhere_flags_re = qr/[$visible_everywhere_flags]/;

my $visible_outside_core_flags = "E$visible_everywhere_flags";
my $visible_outside_core_flags_re = qr/[$visible_outside_core_flags]/;

my $visibility_flags = "$visible_outside_core_flags$never_visible_flags";
my $visibility_flags_re = qr/[$visibility_flags]/;

my $discard_non_visibility_flags_re = qr/[^$visibility_flags]/;

my $error_count = 0;
sub die_at_end ($) { # Keeps going for now, but makes sure the regen doesn't
                     # succeed.
    warn shift;
    $error_count++;
}

sub full_name ($$) { # Returns the function name with potentially the
                     # prefixes 'S_' or 'Perl_'
    my ($func, $flags) = @_;

    if ($flags =~ /[ps]/) {

        # An all uppercase macro name gets an uppercase prefix.
        return (($flags =~ tr/mp// > 1) && $func !~ /[[:lower:]]/)
               ? "PERL_$func"
               : "Perl_$func";
    }

    return "S_$func" if $flags =~ /[SIi]/;
    return $func;
}

sub open_print_header {
    my ($file, $quote) = @_;

    return open_new($file, '>',
                    { file => $file, style => '*', by => 'regen/embed.pl',
                      from => [
                               'embed.fnc',
                               'intrpvar.h',
                               'perlvars.h',
                               'regen/opcodes',
                               'regen/embed.pl',
                               'regen/embed_lib.pl',
                               'regen/HeaderParser.pm',
                           ],
                      final => "\nEdit those files and run 'make regen_headers' to effect changes.\n",
                      copyright => [1993 .. 2026],
                      quote => $quote });
}


sub open_buf_out {
    $_[0] //= "";
    open my $fh,">", \$_[0]
        or die "Failed to open buffer: $!";
    return $fh;
}

my %type_asserts = (
    # Templates for argument type checking for different argument types.
    # __arg__ will be replaced by the parameter variable name

    'AV*' => "SvTYPE(__arg__) == SVt_PVAV",
    'HV*' => "SvTYPE(__arg__) == SVt_PVHV",

    # Any CV* might point at a PVCV or PVFM
    'CV*' => "SvTYPE(__arg__) == SVt_PVCV || SvTYPE(__arg__) == SVt_PVFM",

    # We don't check GV*s for now because too many functions
    # take non-initialised GV pointers
);

# Pointer arguments that erroneously don't indicate whether they can be NULL,
# etc.
my $unflagged_pointers;

# generate proto.h
sub generate_proto_h {
    my ($all)= @_;
    my $pr = open_buf_out(my $proto_buffer);
    my $ret;

    foreach (@$all) {
        if ($_->{type} ne "content") {
            print $pr "$_->{line}";
            next;
        }
        my $embed= $_->{embed}
            or next;

        my $level= $_->{level};
        my $ind= $level ? " " : "";
        $ind .= "  " x ($level-1) if $level>1;
        my $inner_ind= $ind ? "  " : " ";

        my ($flags, $ret_type, $plain_func, $args, $assertions ) =
                        @{$embed}{qw(flags return_type name args assertions)};
        if ($flags =~
             m/([^ aA b C dD eE fF h iI mM nN oO pP Rr sS T uU v W xX ; ])/xx)
        {
            die_at_end "flag $1 is not legal (for function $plain_func)";
        }

        if ($flags =~ /O/) {
            die_at_end "$plain_func: O flag requires p flag" if $flags !~ /p/;
            die_at_end "$plain_func: O flag forbids T flag" if $flags =~ /T/;
        }

        die_at_end "$plain_func: I and i flags are mutually exclusive"
                                                     if $flags =~ tr/Ii// > 1;
        die_at_end "$plain_func: A, C, and S flags are all mutually exclusive"
                                                    if $flags =~ tr/ACS// > 1;
        die_at_end "$plain_func: S and p flags are mutually exclusive"
                                                    if $flags =~ tr/Sp// > 1;
        die_at_end "$plain_func:, M flag requires p flag"
                                            if $flags =~ /M/ && $flags !~ /p/;
        die_at_end "$plain_func: X flag requires one of [Iip] flags"
                                        if $flags =~ /X/ && $flags !~ /[Iip]/;
        die_at_end "$plain_func: [Ii] with [ACX] requires p flag"
                    if $flags =~ /[Ii]/ && $flags =~ /[ACX]/ && $flags !~ /p/;
        if ($flags =~ /b/) {
            die_at_end "$plain_func: b flag without M flag requires D flag"
                                            if $flags !~ /M/ && $flags !~ /D/;
        }

        my $C_required_flags = '[pIimbs]';
        die_at_end
          "$plain_func: C flag requires one of $C_required_flags flags"
                            if $flags =~ /C/
                            && $flags !~ /$C_required_flags/

                            # Notwithstanding the above, if the name won't
                            # clash with a user name, it's ok.
                            && $plain_func !~ $names_reserved_for_perl_use_re;

        my @nonnull;
        my $has_depth = ( $flags =~ /W/ );
        my $never_returns = ( $flags =~ /r/ );
        my $binarycompat = ( $flags =~ /b/ );
        my $has_mflag = ( $flags =~ /m/ );
        my $has_Xflag = ( $flags =~ /X/ );
        my $has_mpflags = $has_mflag && $flags =~ /p/;
        my $is_malloc = ( $flags =~ /a/ );
        my $can_ignore = $flags !~ /[RP]/ && !$is_malloc;
        my $extensions_only = ( $flags =~ /E/ );
        my @asserts;
        my @attrs;
        my $func;
        my $args_assert_line;

        # A function always gets assertions for it
        if (! $has_mflag) {
            $args_assert_line = 1;
        }
        elsif ($has_mpflags && $flags =~ $visible_everywhere_flags_re) {

            # And assertions are created for the automatically generated
            # functions from macros.  No function is needed unless one has
            # been requested (p flag), and is needed.  None is needed if the
            # macro is only visible to core and extensions, as no function
            # gets generated.
            $need_longs{$plain_func} = $args_assert_line = 1;
        }

        # Macros don't have a context parameter unless there is a Perl_ form
        # generated for them.
        my $has_context = ($flags !~ /T/ && (   $need_longs{$plain_func}
                                             || ! $has_mflag));

        if (! $can_ignore && $ret_type eq 'void') {
            warn "It is nonsensical to require the return value of a void"
               . " function ($plain_func) to be checked";
        }

        if ($flags =~ $visible_everywhere_flags_re && $flags =~ /([EX])/) {
            die_at_end "$plain_func: $1 flag is incompatible with either A"
                     . " or C flags";
        }

        if ($has_mflag) {
            if ($flags =~ /([bMSX])/) {
                my $msg =
                         "$plain_func: m and $1 flags are mutually exclusive";
                $msg .= " (try M flag)" if $1 eq 'b';
                die_at_end $msg;
            }

            # Don't generate a prototype for a macro that is not usable by the
            # outside world.
            next unless $flags =~ $visible_outside_core_flags_re;

            # Nor one that is weird, which would likely be a syntax error.
            next if $flags =~ /u/;
        }
        else {
            die_at_end "$plain_func: u flag requires m flag" if $flags =~ /u/;
        }

        my ($static_flag, @extra_static_flags)= $flags =~/([SsIi])/g;

        if (@extra_static_flags) {
            my $flags_str = join ", ", $static_flag, @extra_static_flags;
            $flags_str =~ s/, (\w)\z/ and $1/;
            die_at_end
                     "$plain_func: flags $flags_str are mutually exclusive\n";
        }

        my $retval = $ret_type;
        my $static_inline = 0;
        if ($static_flag) {
            my $type;
            if ($never_returns) {
                $type = {
                    'S' => 'PERL_STATIC_NO_RET',
                    's' => 'PERL_STATIC_NO_RET',
                    'i' => 'PERL_STATIC_INLINE_NO_RET',
                    'I' => 'PERL_STATIC_FORCE_INLINE_NO_RET'
                }->{$static_flag};
            }
            else {
                $type = {
                    'S' => 'static',
                    's' => 'static',
                    'i' => 'PERL_STATIC_INLINE',
                    'I' => 'PERL_STATIC_FORCE_INLINE'
                }->{$static_flag};
            }
            $retval = "$type $retval";
            die_at_end "Don't declare static function '$plain_func' pure"
                                                             if $flags =~ /P/;
            $static_inline = $type =~ /^PERL_STATIC(?:_FORCE)?_INLINE/;
        }
        else {

            # A publicly accessible non-static element needs to have a Perl_
            # prefix available to call it with (in case of name conflicts).
            die_at_end "$plain_func: requires p flag because has A or C flag"
                                    if $flags !~ /p/
                                    && $flags =~ $visible_everywhere_flags_re
                                    && $plain_func !~ /[Pp]erl/;

            if ($never_returns) {
                if ($ret_type eq 'void') {
                    $retval = "PERL_CALLCONV_NO_RET $retval";
                }
                else {
                    $retval = "PERL_CALLCONV_NON_VOID_NO_RET($ret_type) $retval";
                }
            }
            else {
                $retval = "PERL_CALLCONV $retval";
            }
        }

        $func = full_name($plain_func, $flags);
        $ret = "";
        $ret .= "$retval\n";
        $ret .= "$func(";

        if ($has_context) {

            # Pretend there was an aTHX argument in the first position.
            unshift $args->@*, "PerlInterpreter* aTHX NN";

            $ret .= "pTHX";
            $ret .= "_ " if $args->@* > 1;
        }

        if (@$args) {
            die_at_end
                    "$plain_func: n flag is contradicted by having arguments"
                                                             if $flags =~ /n/;
            my $n;
            my @bounded_strings;

            for my $arg ( @$args ) {
                ++$n;

                if ($arg =~ / ^ " (.+) " $ /x) {    # Handle literal string
                    my $name = $1;

                    # Make the string a legal C identifier; 'p' is arbitrary,
                    # and is because C reserves leading underscores
                    $name =~ s/^\W/p/a;
                    $name =~ s/\W/_/ag;

                    $arg = "const char * const $name";
                    die_at_end "$plain_func: func: m flag required for"
                             . '"literal" argument' unless $has_mflag;
                }
                else {  # Look for constraints about this argument

                    my $ptr_type;   # E, M, and S are the three types
                                    # corresponding respectively to EPTR,
                                    # MPTR, and SPTR
                    my $ptr_name;   # The full name of $ptr_type
                    my $equal = ""; # set to "=" if can be equal to previous
                                    # pointer, empty if not
                    if ($arg =~ s/ \b (  EPTRgt
                                       | EPTRge
                                       | EPTRtermNUL
                                       | MPTR
                                       | SPTR )
                                   \b //x)
                    {
                        $ptr_name = $1;
                        $ptr_type = substr($ptr_name, 0, 1);
                        $equal = "=" if $ptr_type eq 'M'
                                     or (   $ptr_type eq 'E'
                                         && $ptr_name !~ /gt/);
                    }

                    # A $ptr_type is a specialized 'nn'
                    my $nn =  (defined $ptr_type) + ( $arg =~ s/\bNN\b// );

                    my $nz =      ( $arg =~ s/\bNZ\b// );
                    my $nullok =  ( $arg =~ s/\bNULLOK\b// );
                    my $nocheck = ( $arg =~ s/\bNOCHECK\b// );

                    # Trim $arg and remove multiple blanks
                    $arg =~ s/^\s+//;
                    $arg =~ s/\s+$//;
                    $arg =~ s/\s{2,}/ /g;

                    # Note that we don't care if you say e.g., 'NN' multiple
                    # times
                    die_at_end
                           ":$func: $arg Use only one of NN (including"
                         . " an EPTR form, MPTR, SPTR), NULLOK, or NZ"
                                               if 0 + $nn + $nz + $nullok > 1;

                    push( @nonnull, $n - $has_context) if $nn;

                    # A non-pointer shouldn't have a pointer-related modifier.
                    # But typedefs may be pointers without our knowing it, so
                    # we can't check for non-pointer issues.  We can only
                    # check for the case where the argument is definitely a
                    # pointer.
                    if ($args_assert_line && $arg =~ /\*/) {
                        if ($nn + $nullok == 0) {
                            warn "$func: $arg needs one of: NN,"
                               . " an EPTR form, MPTR, SPTR, or NULLOK";
                            ++$unflagged_pointers;
                        }

                        warn "$func: $arg should not have NZ\n" if $nz;
                    }

                    # Make sure each arg has at least a type and a var name.
                    # An arg of "int" is valid C, but want it to be "int foo".
                    my $argtype = ( $arg =~ m/^(\w+(?:\s*\*+)?)/ )[0];
                    defined $argtype and $argtype =~ s/\s+//g;

                    my $temp_arg = $arg;
                    $temp_arg =~ s/\*//g;
                    $temp_arg =~
                              s/ \s* \b ( struct | enum | union ) \b \s*/ /xg;
                    if ( ($temp_arg ne "...")
                        && ($temp_arg !~ /\w+\s+(\w+)(?:\[\d+\])?\s*$/) )
                    {
                        die_at_end "$func: $arg ($n) doesn't have a name\n";
                    }
                    my $argname = $1;
                    my $is_aTHX = (   $has_context
                                   && defined $argname
                                   && $argname eq 'aTHX' && $n == 1);

                    if ($is_aTHX) {
                        if ($nn) {
                            push @asserts,  "Perl_assert_aTHX";
                            push @attrs, "Perl_attribute_nonnull_aTHX";
                        }
                    }
                    elsif (   defined $argname
                        && ($args_assert_line || $binarycompat))
                    {
                        if ($nn||$nz) {
                            push @asserts, "assert($argname)";
                            if ($nn) {
                                my $string_n = $n - $has_context;
                                $string_n = "pTHX_$string_n" if $has_context;
                                push @attrs,
                                     "Perl_attribute_nonnull($string_n)";
                            }
                        }

                        if (   ! $nocheck
                            && defined $argtype
                            && exists $type_asserts{$argtype})
                        {
                            my $type_assert =
                             $type_asserts{$argtype} =~ s/__arg__/$argname/gr;
                            $type_assert = "!$argname || $type_assert"
                                                                   if $nullok;
                            push @asserts, "assert($type_assert)";
                        }

                        # If this is a pointer to a character string argument,
                        # we need extra work.
                        if ($ptr_type) {

                            # For these, not only does the parameter have to
                            # be non-NULL, but every dereference of it has to
                            # too.
                            #
                            # First, get all the '*" derefs, except one.
                            my $derefs = "*" x (($arg =~ tr/*//) - 1);

                            # Then add the asserts that each dereferenced
                            # layer is non-NULL.
                            for (my $i = 1; $i <= length $derefs; $i++) {
                                push @asserts, "assert("
                                             . substr($derefs, 0, $i)
                                             . "$argname)";
                            }

                            # Save the data we need later
                            my %entry = (
                                          argname   => $argname,
                                          equal     => $equal,
                                          deref     => $derefs,
                                          name      => $ptr_name,
                                        );

                            # The motivation for all this is that some string
                            # pointer parameters have constraints, such as
                            # that the starting position can't be beyond the
                            # ending one.  Unfortunately, the function's
                            # parameters can be positioned in its prototype so
                            # that the pointer to the ending position comes
                            # before the pointer to the starting one, and this
                            # can't be changed because they are API.  To cope
                            # with this, we use the array below to save just
                            # the crucial information about each while parsing
                            # the parameters.  After all information is
                            # gathered, we go through and handle it.  An entry
                            # looks like this after all the parameters are
                            # parsed:
                            #   {
                            #       'M' => {
                            #               'equal' => '=',
                            #               'argname' => 'curpos',
                            #               'deref' => ''
                            #               'name' => 'MPTR',
                            #               },
                            #       'E' => {
                            #               'equal' => '',
                            #               'argname' => 'strend',
                            #               'deref' => ''
                            #               'name' => some-value,
                            #               },
                            #       'S' => {
                            #               'equal' => '',
                            #               'deref' => '',
                            #               'argname' => 'strbeg'
                            #               'name' => 'SPTR',
                            #               }
                            #   }
                            #
                            # Only two of the keys need be present.
                            # If the function has multiple string parameters,
                            # the [0] entry in @bounded_strings will be for
                            # the first string, [1] for the second, and so on.
                            #
                            # Here, we are in the middle of parsing the
                            # parameters.  We add this parameter to the
                            # current string's boundary constraints hash,
                            # or create a new string if necessary.  The new
                            # string's data is pushed as a new element onto
                            # the array.
                            #
                            # A new element is created if the array is empty,
                            # or if there is already an existing hash element
                            # for the new key.  For example, you can't have
                            # two EPTRs for the same string, so the second
                            # must be for a new string.
                            #
                            # Otherwise we presume this hash value is for the
                            # most recent string in the array.  If we have an
                            # EPTR, and an MPTR comes along, assume that it is
                            # for the same string as the EPTR.
                            #
                            # This hack works as long as all parameters for the
                            # current string come before any of the next
                            # string, which is the case for all existing
                            # function calls, and any new ones can be
                            # fashioned to conform.
                            if (   @bounded_strings
                                && ! defined $bounded_strings[-1]{$ptr_type})
                            {
                                $bounded_strings[-1]{$ptr_type} = \%entry;
                            }
                            else {
                                push @bounded_strings,
                                     { $ptr_type => \%entry };
                            }
                        }   # End of special handling of string bounds
                    }
                }   # End of this argument
            }   # End of loop through all arguments

            # We have looped through all arguments, and for any bounded string
            # ones, we have saved the information needed to generate things
            # like
            #   assert(s < e)
            foreach my $string (@bounded_strings) {

                # We need at least two bounds
                if (1 == (  (defined $string->{S})
                          + (defined $string->{M})
                          + (defined $string->{E})))
                {
                    my ($type, $object) = each %$string;
                    die_at_end
                           "$func: Missing PTR constraint for string given by "
                         . $object->{argname};
                    next;
                }

                # But three or any two bounds work.  We may need to generate
                # two asserts, so loop to do so, skipping any missing one.
                for my $i (["S", "E"], ["S", "M"], ["M", "E"]) {

                    # We don't need an assert for the whole span if we have an
                    # intermediate one.
                    next if defined $string->{M} &&    $i->[0] eq 'S'
                                                    && $i->[1] eq 'E';

                    my $lower_obj= $string->{$i->[0]} or next;
                    my $upper_obj= $string->{$i->[1]} or next;
                    my $lower = "$lower_obj->{deref}$lower_obj->{argname}";
                    my $upper= "$upper_obj->{deref}$upper_obj->{argname}";

                    if ($upper_obj->{name} eq 'EPTRtermNUL') {
                            push @asserts, "assert($lower <= $upper)";
                            push @asserts, "assert(*$upper == '\\0')";
                    }
                    else {
                        my $equal = $upper_obj->{equal};

                        # This reduces to either;
                        #   assert(lower < upper);
                        # or
                        #   assert(lower <= upper);
                        #
                        # There might also be some derefences, like **lower
                        push @asserts, "assert($lower <$equal $upper)";
                    }
                }
            }

            shift $args->@* if $has_context;    # Remove implicit aTHX arg
            $ret .= join ", ", @$args;
        }
        else {
            $ret .= "void" if !$has_context;
        }
        $ret .= " comma_pDEPTH" if $has_depth;
        $ret .= ")";

        push @asserts, @$assertions if $assertions;

        if ( $flags =~ /r/ ) {
            push @attrs, "__attribute__noreturn__";
        }
        if ( $flags =~ /D/ ) {
            push @attrs, "__attribute__deprecated__";
        }
        if ( $is_malloc ) {
            push @attrs, "__attribute__malloc__";
        }
        if ( !$can_ignore ) {
            push @attrs, "__attribute__warn_unused_result__";
        }
        if ( $flags =~ /P/ ) {
            push @attrs, "__attribute__pure__";
        }
        if ( $flags =~ /I/ ) {
            push @attrs, "__attribute__always_inline__";
        }
        # roughly the inverse of the rules used in makedef.pl
        if ( $flags !~ /[AbCeIimSX]/ ) {
            push @attrs, '__attribute__visibility__("hidden")'
        }
        if( $flags =~ /f/ ) {
            my $prefix  = $has_context ? 'pTHX_' : '';
            my ($argc, $pat);
            if (!defined $args->[1]) {
                use Data::Dumper;
                die Dumper($_);
            }
            if ($args->[-1] eq '...') {
                $argc   = scalar @$args;
                $pat    = $argc - 1;
                $argc   = $prefix . $argc;
            }
            else {
                # don't check args, and guess which arg is the pattern
                # (one of 'fmt', 'pat', 'f'),
                $argc = 0;
                my @fmts = grep $args->[$_] =~ /\b(f|pat|fmt)$/, 0..$#$args;
                if (@fmts != 1) {
                    die
                    "embed.pl: '$plain_func': can't determine pattern arg\n";
                }
                $pat = $fmts[0] + 1;
            }
            my $macro   = grep($_ == $pat, @nonnull)
                                ? '__attribute__format__'
                                : '__attribute__format__null_ok__';
            if ($plain_func =~ /strftime/) {
                push @attrs, sprintf "%s(__strftime__,%s1,0)",
                                     $macro, $prefix;
            }
            else {
                push @attrs, sprintf "%s(__printf__,%s%d,%s)", $macro,
                                    $prefix, $pat, $argc;
            }
        }
        elsif ((grep { $_ eq '...' } @$args) && $flags !~ /F/) {
            die_at_end "$plain_func: Function with '...' arguments must have"
                     . " f or F flag";
        }

        if ( @attrs ) {
            $ret .= "\n"
                 .  join( "\n", map { (" " x 8) . $_ } @attrs);
        }
        $ret .= ";";
        $ret = "/* $ret */" unless $args_assert_line;

        # Hide the prototype from non-authorized code.  This acts kind of like
        # __attribute__visibility__("hidden") for cases where that can't be
        # used.
        $ret = "#${ind}if defined(PERL_CORE) || defined(PERL_EXT)\n"
             . $ret
             . "\n#${ind}endif"
          if $extensions_only && ! $has_Xflag;

        # We don't hide the ARGS_ASSERT macro; having that defined does no
        # harm, and otherwise some inline functions that are looking for it
        # would fail to compile.
        if ($args_assert_line || @asserts) {
            $ret .= "\n#${ind}define PERL_ARGS_ASSERT_\U$plain_func\E";
            if (@asserts) {
                $ret .= " \\\n";

                my $line = "";
                while(@asserts) {
                    my $assert = shift @asserts;

                    if(length($line) + length($assert) > 78) {
                        $ret .= $line . "; \\\n";
                        $line = "";
                    }

                    $line .= " " x 8 if !length $line;
                    $line .= "; " if $line =~ m/\S/;
                    $line .= $assert;
                }

                $ret .= $line if length $line;
                $ret .= "\n";
            }
        }
        $ret .= "\n";

        $ret = "#${ind}ifndef PERL_NO_INLINE_FUNCTIONS\n$ret\n#${ind}endif"
            if $static_inline;
        $ret = "#${ind}ifndef NO_MATHOMS\n$ret\n#${ind}endif"
            if $binarycompat;

        $ret .= @attrs ? "\n\n" : "\n";

        print $pr $ret;
    }


    close $pr;

    my $clean= normalize_group_content($proto_buffer);

    my $fh = open_print_header("proto.h");

    print $fh <<~"EOF";
        #ifdef DEBUGGING    /* See GH #23641 */
        #  define Perl_attribute_nonnull(which)
        #else
        #  define Perl_attribute_nonnull(which)  __attribute__nonnull__(which)
        #endif

        #if defined(MULTIPLICITY)
          #  define Perl_assert_aTHX             assert(aTHX)
          #  define Perl_attribute_nonnull_aTHX  __attribute__nonnull__(1)
        #else
          #  define Perl_assert_aTHX
          #  define Perl_attribute_nonnull_aTHX
        #endif

        START_EXTERN_C
        $clean
        #ifdef PERL_CORE
        #  include "pp_proto.h"
        #endif
        END_EXTERN_C
        EOF

    read_only_bottom_close_and_rename($fh) if ! $error_count;
}

{
    my $hp= HeaderParser->new();
    sub normalize_group_content {
        open my $in, "<", \$_[0]
            or die "Failed to open buffer: $!";
        $hp->parse_fh($in);
        my $ppc= sub {
            my ($self, $line_data)= @_;
            # re-align defines so that the definitions line up at the 48th col
            # as much as possible.
            if ($line_data->{sub_type} eq "#define") {
                $line_data->{line} =~
                        s/^(\s*#\s*define\s+\S+?(?:\([^()]*\))?\s)(\s*)(\S+)/
                    sprintf "%-48s%s", $1, $3/e;
            }
        };
        my $clean= $hp->lines_as_str($hp->group_content(),$ppc);
        return $clean;
    }
}

sub normalize_and_print {
    my ($file, $buffer)= @_;
    my $fh = open_print_header($file);
    print $fh normalize_group_content($buffer);
    read_only_bottom_close_and_rename($fh);
}


sub readvars {
    my ($file, $pre) = @_;
    my $hp= HeaderParser->new()->read_file($file);
    my %seen;
    foreach my $line_data (@{$hp->lines}) {
        #next unless $line_data->is_content;
        my $line= $line_data->line;
        if ($line=~m/^\s*PERLVARA?I?C?\(\s*$pre\s*,\s*(\w+)/){
            $seen{$1}++
                and
                die_at_end "duplicate symbol $1 while processing $file line "
                       . ($line_data->start_line_num) . "\n"
        }
    }
    my @keys= sort { lc($a) cmp lc($b) ||
                        $a  cmp    $b }
              keys %seen;
    return @keys;
}

sub add_indent {
    #my ($ret, $add, $width)= @_;
    my $width= $_[2] || 48;
    $_[0] .= " " x ($width-length($_[0])) if length($_[0])<$width;
    $_[0] .= " " unless $_[0]=~/\s\z/;
    if (defined $_[1]) {
        $_[0] .= $_[1];
    }
    return $_[0];
}

sub indent_define {
    my ($from, $to, $indent, $width) = @_;
    $indent = '' unless defined $indent;
    my $ret= "#${indent}define $from";
    add_indent($ret,"$to\n",$width);
}

sub multon {
    my ($sym,$pre,$ptr,$ind) = @_;
    $ind//="";
    indent_define("PL_$sym", "($ptr$pre$sym)", $ind);
}

sub embed_h {
    my (
        $em,    # file handle
        $guard, # ifdef text
        $funcs  # functions to go into this text
       ) = @_;

    my $lines;
    foreach (@$funcs) {
        my $object = $_;
        if ($object->{type} ne "content") {
            $lines .= $object->{line};
            next;
        }
        my $level= $object->{level};
        my $embed= $object->{embed} or next;
        my ($flags,$retval,$func,$args) =
                                   @{$embed}{qw(flags return_type name args)};

        # Macros with [oO] don't appear without a [Pp]erl_ prefix, so nothing
        # to undef
        if ($flags =~ /m/ && $flags !~ /[oO]/) {
            if ($flags !~ $visible_outside_core_flags_re) {
                $always_undefs{$func} = 1
                  unless defined $unresolved_visibility_overrides{$func};
            }
            elsif ($flags =~ /E/) {     # Visible to perl extensions
                $non_ext_undefs{$func} = 1
                  unless defined $unresolved_visibility_overrides{$func}
                      or defined $needed_by_ext{$func};
            }
        }

        my $full_name = full_name($func, $flags);
        next if $full_name eq $func;    # Don't output a no-op.

        my $ret = "";
        my $ind= $level ? " " : "";
        $ind .= "  " x ($level-1) if $level>1;
        my $inner_ind= $ind ? "  " : " ";

        if ($flags =~ tr/mp// > 1) {    # Has both m and p

            # Here is the case where the code implements the functionality
            # with a macro, and we're supposed to create a long name synonym
            # for it.  The long name should work even if the XS code
            # #undefines the short name (this would happen because it
            # conflicts with their name).  If there's no thread context, the
            # naive implementation would be to just copy the macro expansion.
            # But what if that expansion uses a short name that has also been
            # #undefined?  The only thing that works in all cases is to create
            # a function named with the long name, and have it call the short
            # name macro.  XXX The naive approach could still work for
            # "simple" enough expansions.
            #
            # Another thing to consider is that we can't discard the thread
            # context for elements visible outside core is because of the
            # possibility of embedding.  Suppose a program contains two
            # embedded perl instances.  It calls the various long form
            # functions with whatever thread context it wants.  We can't just
            # ignore that context, so an actual function needs to be created
            # to pass the context to.
            #
            # But we don't have to worry about collisions for functions that
            # are visible only to core or its extensions
            if ($flags =~ /[T]/ && $flags !~ $visible_everywhere_flags_re) {
                # Yields
                #   #define Perl_func  func
                # which works when there is no thread context.
                $ret = indent_define($full_name, $func, $ind);
            }
            else {

                # Here, there is thread context and/or the function is visible
                # outside the perl coccoon.  We will have to deal with the
                # arguments.  Create the base argument list by converting the
                # input argument list to 'a', 'b' ....  This keeps us from
                # having to worry about all the extra stuff in the input list;
                # stuff like the type declarations, things like NULLOK, and
                # pointers '*'.
                my $argname = 'a';
                my @stripped_args;
                push @stripped_args, $argname++ for $args->@*;
                my $arglist = join ",", @stripped_args;

                if ($flags =~ $visible_everywhere_flags_re) {

                    # For elements visible outside core, we need to generate a
                    # function to implement the macro.  This is done elsehwere
                    # in the program after everything is gathered, using the
                    # information that we save now.
                    $object->{guard} = $guard;
                    $need_longs{$full_name} = $object;
                }
                else {

                    # Here, the visibility is restricted so that we don't have
                    # to worry about the short name getting undefined.  We
                    # already took care of the case where there isn't a thread
                    # context.  But here, we have different code handling
                    # threaded/unthreaded.  For unthreaded, there is no actual
                    # thread context parameter, so the short and long versions
                    # are identical.
                    $ret = "#${ind}ifndef USE_THREADS\n"
                         . indent_define("$full_name($arglist)",
                                         "$func($arglist)", $ind)
                         . "#${ind}else\n";

                    # But for threaded builds, the macro doesn't have an
                    # explicit thread context argument, but the long name
                    # does.  We just discard the thread context passed to the
                    # long form and call the short form macro whose expansion
                    # adds it back in.
                    my $mTHX_ = "mTHX";
                    $mTHX_ .= ',' if $arglist ne "";

                    $ret .= indent_define("$full_name($mTHX_$arglist)",
                                         "$func($arglist)", $ind)
                         . "#${ind}endif\n";
                }
            }
        }
        elsif ($flags !~ /[omM]/) {
            my $argc = scalar @$args;
            if ($flags =~ /[T]/) {
                $ret = indent_define($func, $full_name, $ind);
            }
            else {
                my $use_va_list = $argc && $args->[-1] =~ /\.\.\./;

                if($use_va_list) {
                    # CPP has trouble with empty __VA_ARGS__ and comma
                    # joining, so we'll have to eat an extra params here.
                    if($argc < 2) {
                        die "Cannot use ... as the only parameter to a macro"
                          . " ($func)\n";
                    }
                    $argc -= 2;
                }

                my $paramlist   = join(",", @az[0..$argc-1],
                    $use_va_list ? ("...") : ());
                my $replacelist = join(",", @az[0..$argc-1],
                    $use_va_list ? ("__VA_ARGS__") : ());
                $ret = "#${ind}define $func($paramlist) ";
                add_indent($ret,full_name($func, $flags) . "(aTHX");
                if ($replacelist) {
                    $ret .= ($flags =~ /m/) ? "," : "_ ";
                    $ret .= $replacelist;
                }

                if ($flags =~ /W/) {
                    if ($replacelist) {
                        $ret .= " comma_aDEPTH";
                    } else {
                        die "Can't use W without other args (currently)";
                    }
                }
                $ret .= ")";

                # For functions that have an old 'perl_' name, create an entry
                # here while we have all the information, for output later
                # (when not under NO_SHORT_NAMES)
                if ($flags =~ /O/) {
                    my $extra_entry = $ret;
                    $extra_entry =~ s/define /define perl_/;
                    $perl_compats{$extra_entry} = 1;
                }

                $ret .= "\n";

                if($has_compat_macro{$func}) {
                    # Make older ones available only when !MULTIPLICITY or
                    # PERL_CORE or PERL_WANT_VARARGS.  These should not be
                    # done unconditionally because existing code might call
                    # e.g.  warn() without aTHX in scope.
                    $ret = "#${ind}if !defined(MULTIPLICITY)"
                         . " || defined(PERL_CORE)"
                         . " || defined(PERL_WANT_VARARGS)\n"
                         . $ret
                         . "#${ind}endif\n";
                }

            }
            $ret = "#${ind}ifndef NO_MATHOMS\n$ret#${ind}endif\n"
                                                             if $flags =~ /b/;
        }
        $lines .= $ret;
    }
    # remove empty blocks
    1 while $lines =~ s/^#\s*if.*\n#\s*endif.*\n//mg
         or $lines =~ s/^(#\s*if)\s+(.*)\n#else.*\n/$1 !($2)\n/mg;
    if ($guard) {
        print $em "$guard /* guard */\n";
        $lines=~s/^#(\s*)/"#".(length($1)?"  ":" ").$1/mge;
    }
    print $em $lines;
    print $em "#endif\n" if $guard;
}

sub generate_embed_h {
    my ($all, $api, $ext, $core)= @_;

    my $em= open_buf_out(my $embed_buffer);

    print $em <<~'END';
    /* (Doing namespace management portably in C is really gross.) */

    /* When this symbol is defined, we undef various symbols we have defined
     * earlier when this file was #included with this symbol undefined */
    #if ! defined(PERL_DO_UNDEFS)

    /* Create short name macros that hide any need for thread context */

    END

    embed_h($em, '', $api);
    embed_h($em, '#if defined(PERL_CORE) || defined(PERL_EXT)', $ext);
    embed_h($em, '#if defined(PERL_CORE)', $core);

    print $em <<~'END';

    #if !defined(PERL_CORE)
    /* Compatibility stubs.  Compile extensions with -DPERL_NOCOMPAT to
     * disable them.
     */
    #  define sv_setptrobj(rv,ptr,name) sv_setref_iv(rv,name,PTR2IV(ptr))
    #  define sv_setptrref(rv,ptr)      sv_setref_iv(rv,NULL,PTR2IV(ptr))
    #endif

    #if !defined(PERL_CORE) && !defined(PERL_NOCOMPAT)

    /* Compatibility for this renamed function. */
    #  define perl_atexit(a,b)          Perl_call_atexit(aTHX_ a,b)

    /* Compatibility for these functions that had a 'perl_' prefix before
     * 'Perl_' became the standard */
    END

    # These have been saved up for now
    print $em map { "$_\n" } sort keys %perl_compats;

    print $em <<~'END';

    /* Before C99, macros could not wrap varargs functions. This
       provides a set of compatibility functions that don't take an
       extra argument but grab the context pointer using the macro dTHX.
     */
    #if defined(MULTIPLICITY) && !defined(PERL_WANT_VARARGS)
    END

    foreach (@have_compatibility_macros) {
        print $em indent_define($_, "Perl_${_}_nocontext", "  ");
    }

    print $em <<~'END';
    #endif

    #endif /* !defined(PERL_CORE) && !defined(PERL_NOCOMPAT) */

    #if !defined(MULTIPLICITY)
    /* undefined symbols, point them back at the usual ones */
    END

    foreach (@have_compatibility_macros) {
        print $em indent_define("Perl_${_}_nocontext", "Perl_$_", "  ");
    }

    print $em <<~EOT;
        #endif    /* !defined(MULTIPLICITY) */
        #elif ! defined(PERL_CORE)
    EOT

    # We undefine all elements on the list of symbol names to keep from user
    # name space if PERL_NO_SHORT_NAMES is in effect (which requests this),
    # but override it if are compiling the core.
    for my $i (
                [ "", \%always_undefs ],
                [ '#ifndef PERL_EXT_RE_BUILD', \%non_ext_re_undefs ],
                [ '#ifndef PERL_EXT', \%non_ext_undefs ],
              )
    {
        my $ifdef = $i->[0];
        my $hash = $i->[1];

        print $em $ifdef, "\n" if $ifdef;
        for my $name ( sort {    lc $a cmp lc $b
                              or    $a cmp    $b
                            } keys %{$hash})
        {
            print $em "#undef $name\n";
        }
        print $em "#endif\n" if $ifdef;
    }

    print $em "#endif\n";

    close $em;

    normalize_and_print('embed.h',$embed_buffer)
        unless $error_count;
}

sub generate_embedvar_h {
    my $em = open_buf_out(my $embedvar_buffer);

    print $em "#if defined(MULTIPLICITY)\n",
              indent_define("vTHX","aTHX"," ");


    my @intrp = readvars 'intrpvar.h','I';
    #my @globvar = readvars 'perlvars.h','G';


    for my $sym (@intrp) {
        my $ind = " ";
        if ($sym eq 'sawampersand') {
            print $em "# if !defined(PL_sawampersand)\n";
            $ind = "   ";
        }
        my $line = multon($sym, 'I', 'vTHX->', $ind);
        print $em $line;
        if ($sym eq 'sawampersand') {
            print $em "# endif /* !defined(PL_sawampersand) */\n";
        }
    }

    print $em "#endif       /* MULTIPLICITY */\n";
    close $em;

    normalize_and_print('embedvar.h',$embedvar_buffer)
        unless $error_count;
}

# Below is code to fill this hash with data about the visibility of each macro
# that is potentially visible to XS code.  There is the visibility it is
# supposed to have given by flags in its apidoc descriptions, and the actual
# visibility imposed by C preprocessor conditionals around its #definition.
# This program checks for and reconciles any disparities between them.
my %visibility;

sub set_flags_visibility {
    my ($name, $file, $line_number, $raw_flags) = @_;

    # Store $name's requested visibility into $visibility{$name}{flags} as
    # determined by apidoc or embed.fnc lines.  The visibility is stored as
    # a single character mnemonic, as follows:
    #   0   The symbol is not supposed to be visible outside the perl core
    #   E   The symbol is supposed to be visible to perl extensions and the
    #       core but nowhere else
    #   1   The symbol is supposed to be visible everywhere

    # Use the stored flags if new ones empty.  If those don't exist, assume
    # visible everywhere for symbols that Perl reserves for its use, and
    # hidden visibility for everything else.
    my $flags = $raw_flags // $visibility{$name}{flags_raw};
    if (! defined $flags) {
        if ($name =~ $names_reserved_for_perl_use_re) {
            $flags = 'A';

            # But note that this is an assumption; so can avoid warning later.
            $visibility{$name}{flags_implicit} = 1;
        }
        else {
            $flags = 'e';
        }
    }

    my $is_macro = $flags =~ /m/;

    # Convert never to 0; always to 1; 'E' remains 'E'.
    $flags =~ s/$discard_non_visibility_flags_re//g;
    if ($flags =~ s/E//g) {
        $flags .= 'E';          # Squeeze out multiple E's
        $flags =~ s/[eX]//g;    # These flags are irrelevant for our purposes
        if ($flags ne 'E') {
            die_at_end "'E' flag for $name can't have other visibility flag"
                     . " except [eX], not '$raw_flags'; in $file line"
                     . " $line_number";
            $flags = 'E';
        }
    }
    elsif ($flags eq "" || $flags =~ $never_visible_flags_re) {
        $flags = 0;
    }
    else {
        $flags = 1;
    }

    # There are often cases where the same symbol has multiple entries, for
    # example one for Win32, another for everything else; or one for threaded
    # vs unthreaded, etc.  We want to find the most visible one.  To that end
    # we compare the visibilities of the new and stored, and replace if the
    # new one is more visible.
    #
    # If there isn't an already-stored one, set its visibility to -1, which is
    # more restrictive than any new one, so this new one will automatically
    # prevail.
    my $stored_ordering = $visibility{$name}{flags_ordering} // -1;

    # Compute an ordering for this flag, to more easily compare later.  This
    # ended up being less code than writing specific comparisons.
    my $ordering;

    # Multiply to get the numeric numbers spread more widely than the
    # non-numeric one.
    if ($flags =~ / ^ -? \d+ $/x) {
        $ordering = 2 * $flags;
    }
    elsif ($flags eq 'E') {
        $ordering = 1;
    }
    else {
        die_at_end "Flag for $name '$flags' unrecognized in $file line"
                 . " $line_number";
        $ordering = -1;
    }

    # Do nothing unless new one is more visible than old
    return if $stored_ordering >= $ordering;

    $visibility{$name}{flags} = $flags;
    $visibility{$name}{flags_ordering} = $ordering;
    $visibility{$name}{flags_raw} = $raw_flags;
    $visibility{$name}{flags_file} = $file;
    $visibility{$name}{flags_file_line_number} = $line_number;
    $visibility{$name}{is_macro} = $is_macro;
    return;
}

sub get_and_set_cpp_visibility {
    my ($name, $line) = @_;

    # Store $name's actual visibility, as determined by the C preprocessor,
    # into $visibility{$name}{cpp}, while returning the stringified cpp
    # expression that determines the symbol's visibility, with any
    # subexpressions whose values are known factored out.  The result is
    #   0       the expression is never true outside the Perl core or
    #           extensions to it
    #   1       the expression is always true outside the Perl core or
    #           extensions to it
    #   string  Something like 'defined(a) && ( !defined(b) || defined(c) )'
    #           giving the conditions for which the expression is true
    #
    # $line points to the HeaderLine object that contains $name.

    # The stored visibility is the same as the codes used in
    # set_flags_visibility(), plus
    #   /   The symbol is visible in the 'use re' extension, plus the perl
    #       core, but nowhere else

    my $file = $line->{source};

    # We get called for both #define and #undef lines.  Determine which
    my $is_define = $file =~ m! embed\.fnc | regen/opcodes !x
                 || (   defined $line->{sub_type}
                     && $line->{sub_type} eq '#define');
    if (! $is_define && (   ! defined $line->{sub_type}
                         || $line->{sub_type} ne '#undef'))
    {
        use Data::Dumper;
        die "Unexpected line\n" . Dumper $line
    }

    # The base cpp conditionals for every line in this file
    my %this_file_conds;

    # The goal is to evaluate the cpp conditionals down to as close to just 0
    # or 1 as possible.  To that end, we may have specified the values to
    # assume some conditional terms are.  If so, use those.  If not, use
    # some of our source code conventions for header files.
    my $this_file_override = $per_file_definitions{$file};
    if (defined $this_file_override) {
        while (my ($name, $value) = each $this_file_override->%*) {
            $this_file_conds{$name} = $value;
        }
    }
    elsif ($file =~ / (.*) \. (?: h | inc ) $ /x) {

        # Here is a header file.  Some header files have a guard against being
        # #include'd recursively.  It looks like
        #   #ifndef guard
        #   #  define guard
        #   ... rest of file ...
        #   #endif  /* last line of file. */
        # (The actual guard #define can come anywhere between the #ifndef and
        # #endif)
        # Assuming the value of that guard to be 0 accurately removes that
        # conditional from the equation .
        #
        # For file foo, in most cases, the guard is either of the form
        # 'PERL_FOO_H' or 'PERL_FOO_H_'  (except no PERL is added if foo
        # already has that substring caselessly).
        #
        # Create rules for both potential guard forms
        my $file_base = uc $1;
        $file_base = "PERL_$file_base" unless $file_base =~ /PERL/;
        $file_base .= "_H";
        $this_file_conds{$file_base} = 0;
        $this_file_conds{"${file_base}_"} = 0;
    }

    # my %visibility_types has stored in it values to assume various
    # conditional terms are, given the type of visibility.  We add the
    # per-file ones computed above.  Then we see if this symbol is visible for
    # each type.  If the visibility evaluates to 0, it means there is no
    # combination of conditions that lead to the symbol being visible with
    # this type.  If it evaluates to anything else, there is.  Remember it
    # could evaluate to plain 1, or to some string like
    #   #if defined(a) || defined(b).
    # If the result is like that, it means that there is some combination of
    # conditions for which the symbol is visible.
    my $cond_as_string;
    my $visibility_code;

    # See if the symbol is visible everywhere; and if not, if it is visible to
    # 'use 're'; and if not, if it is visible to other extensions.
    for my $code (1, '/', 'E') {
        my %hash = (%this_file_conds, $visibility_types{$code}->%*);
        my $pattern = join "|", keys %hash;
        my $regex = qr/ \b defined \( ( $pattern ) \) /x;
        $cond_as_string = $line->reduce_conds($regex, \%hash);
        next unless $cond_as_string;

        $visibility_code = $code;
        goto found_visibility;
    }

    # No visibilty outside core
    $visibility_code = 0;

  found_visibility:

    # For the defining case, if there already has been an entry for $name,
    # override it iff the new value is more widely visible.
    #
    # For the undefining case, we only undefine if we're pretty sure that it
    # is appropriate to do so.  Any complications found mean we don't
    # undefine.

    # Use the same algorithm as in set_flags_visibility() to see if this new
    # item has wider visibility than any stored (previously encountered) one.
    my $ordering;
    if ($visibility_code =~ / ^ -? \d+ $/x) {
        $ordering = 3 * $visibility_code;
    }
    elsif ($visibility_code eq 'E') {
        $ordering = 2;
    }
    elsif ($visibility_code eq '/') {
        $ordering = 1;
    }
    else {
        die_at_end "Internal code '$visibility_code' unrecognized";
        $ordering = -1;
    }

    my $stored_ordering = $visibility{$name}{cpp_ordering};

    # Return without updating:
    #   1) If the old visibility is wider than the new.
    #   2) And if it is a #define, if the old is equal to the new.  This is
    #      because the new won't replace it.  (But an #undef of the same
    #      visibility could override the old.)
    return $cond_as_string if defined $stored_ordering
                           && (   $stored_ordering > $ordering
                               || (   $is_define
                                   && $stored_ordering == $ordering));
    if ($is_define == 0) {

        # Here we are undefining a symbol.  If there are circumstances under
        # which it doesn't get executed, we have to assume it doesn't, so that
        # we consider the symbol to remain visible.  In case of uncertainty,
        # we err on the side that the symbol remains visible.

        # Do nothing if there is no symbol to undefine.
        return $cond_as_string unless defined $visibility{$name};

        # Do nothing if the symbol already isn't visible;
        my $define_visibility_code = $visibility{$name}{cpp};
        return $cond_as_string unless $define_visibility_code;

        # Do nothing if we can't find information about the definition that
        # would allow us to check the safety.
        my $definer = $visibility{$name}{cpp_defining_object};
        return $cond_as_string unless defined $definer;

        # Don't undef if the symbol was created in a different file than this
        # one.  Otherwise, it is unclear what is meant.
        return $cond_as_string unless $definer->{source} eq $file;

        # Do #undef if the #undef is unconditional or has the precise same
        # constraints as the previous #define.  (This misses cases where
        # things are the same but are in a different order.)
        my $define_cond_as_string = $visibility{$name}{cpp_cond_as_string};
        if (   $cond_as_string ne '1'
            && $cond_as_string ne $define_cond_as_string)
        {
            # Here the stringified versions of the conditions for the #define
            # and the #undef aren't the same.  That happens only if some of
            # the values of the conditions are not known to us, and may not be
            # knowable, as they may vary, dependent on the platform and
            # Configuration.  What we're really after is "Does the #undef
            # happen no matter what the #define conditions are set to?"  If
            # the #undef's conditions include terms that aren't in the
            # #define's, then the answer is that the #undef depends on
            # something besides what the #define depends on, and so won't
            # always be executed.  We could fairly easily rule that case out.
            # But the rest is still hard.  One way, without anlayzing the
            # expressions, would be to try every possible combination of the
            # unresolved #define conditions and verify that whenever the
            # #define happens, the #undef does too.  But that's a lot of work,
            # and with very little payoff, since our existing headers don't
            # tend to have conditions that actually would benefit from this.
            #
            # One case is easy, and does help with current data:  If the
            # #undef conditions have ended up with a single value, we can
            # simply see if that value is also in the #define conditions.
            # Note that if the #define has extra conditions, it just means the
            # #define happens under fewer circumstances than the #undef.
            return $cond_as_string
                    unless $cond_as_string =~
                                    m/ ^ \s* (!)? (defined\(\w+\) ) \s* $ /xg;
            my $complement = $1 // "";
            my $term = $2;

            # Not only must the term be in the #define conditions, but it must
            # have the same type of being complemented.
            if ($complement) {
                return $cond_as_string
                                  unless $define_cond_as_string =~ /\Q!$term/;
            }
            else {
                return $cond_as_string
                          unless $define_cond_as_string =~ / (?!!) \Q$term /x;
            }
        }

        # Here, the #undef matches the #define, so the #undef happens, and the
        # symbol is not visible.
        $ordering = $visibility_code = 0;
    }

    $visibility{$name}{cpp} = $visibility_code;
    $visibility{$name}{cpp_ordering} = $ordering;
    $visibility{$name}{cpp_defining_object} = $line;
    $visibility{$name}{cpp_cond_as_string} = $cond_as_string;
    $visibility{$name}{is_macro} = $line->{type} eq 'content'
                       && defined $line->{sub_type}
                       && $line->{sub_type} =~ / ^ \# ( define | undef ) $ /x;
    return $cond_as_string;
}

sub process_apidoc_lines {
    my $file = shift;
    my $line_number = shift;
    $line_number--;     # So increment below will have no effect first time

    # Look through the input array of lines for ones that can declare the
    # visibility of a symbol, and save those declarations for later use.

    my $group_flags;
    for my $individual_line (@_) {
        $line_number++;

        # Only apidoc lines affect visibility; ignore the rest
        next unless $individual_line =~
                        m/ ^=for \s+ apidoc
                          ( \b | _defn | _item | _flag ) \b
                          \s* (.+)
                         /x;
        my $type = $1;

        # Every such line will have at least one field, which for now we will
        # assume is the name.
        my ($name, @rest) = split /\s*\|\s*/, $2;
        my $flags = "";

        # If only one field, we are done; there are no flags.
        if (@rest != 0) {

            # But otherwise, the flags are in the 0th position.  And the name
            # is later
            $flags = $name;

            # For the non-'apidoc_flag' types, the next parameter is the
            # return (whose value doesn't matter to us here).  It is mandatory
            # (even if empty)
            shift @rest if $type ne '_flag';

            $name = shift @rest;
        }

        # apidoc lines may come in blocks with the first line being
        # 'apidoc', and the remaining ones 'apidoc_item' or 'apidoc_flag'.
        # These are interpreted as groups with the flags parameter of the
        # 'apidoc' line applying to the rest, though those may add flags
        # individually.
        if ($type =~ / ^ (?: _defn )? $ /x ) {
            $flags ||= $visibility{$name}{flags_raw};
            $group_flags = $flags;
        }
        elsif ($type eq '_flag') {
            if ($flags =~ /$discard_non_visibility_flags_re/) {
                die_at_end "Only flags affecting visibility allowed in"
                            . " 'apidoc_flag' lines '$individual_line'";
                next;
            }

            if ($flags) {
                # Override the group's visibility flags with this entry's
                my $non_visibility = $group_flags;
                $non_visibility =~ s/$visibility_flags_re//g;
                $flags .= $non_visibility;
            }
            else {
                $flags = $group_flags;
            }

            # And this is actually a macro
            $flags .= 'm';
        }
        elsif ($type eq '_item') {
            if ($flags) {

                # Non-initial line with flags of its own; add them to the
                # group's
                $flags .= $group_flags;
            }
            else {  # Non-initial line without flags of its own
                $flags = $group_flags;
            }
        }
        else {
            die_at_end "Unknown line '$individual_line'";
            next;
        }

        set_flags_visibility($name, $file, $line_number, $flags);
    }
}

sub find_undefs {
    my $fnc = shift;    # embed.fnc data

    # This program attempts to enforce macro visibility restrictions outside
    # core.  This subroutine finds the symbols that need to be undefined when
    # those restrictions aren't met.
    #
    # A symbol can only be visible if its definition is in a #included header
    # file.  So we only look for those definitions in header files, and
    # embed.fnc, which is the data behind embed.h (and proto.h).  We care here
    # only about the macros that aren't the short-names for functions.  (Those
    # are handled by a different area of this file.)  Each function (since
    # 0351a62, v5.37.1) is hidden from the outside on most platforms by
    # default, unless overridden by a visibility flag.  #ifdefs can further
    # restrict the visibility.

    foreach my $entry ($fnc->@*) {
        my $embed = $entry->embed;

        # Only lines that have this are interesting to us.  Lines that don't
        # have it are typically '#if' lines in the file.  (These are
        # meaningful to HeaderParser which has already parsed them and used
        # their information to create auxiliary data for the lines we do care
        # about.)
        next unless $embed;

        # Find out what visibility constraints those conditions impose on
        # every other line.
        get_and_set_cpp_visibility($embed->name, $entry);

        # embed.fnc lines also have visibility flags to specify the desired
        # visibility of the symbol.
        set_flags_visibility($embed->name, 'embed.fnc',
                             $embed->{start_line_num},  $embed->{flags});
    }

    # Done with embed.fnc.  Now look through all the header files for their
    # symbols.
    foreach my $hdr (@header_list) {

        # Parse the header
        my $lines = HeaderParser->new()->read_file($hdr)->lines();
        foreach my $line ($lines->@*) {

            # We are here looking only for #defines, #undefs, and visibility
            # declarations
            next unless $line->{type} eq 'content';

            # #undef's
            if ($line->{sub_type} eq '#undef') {
                my $flat = $line->{flat};
                $flat =~ / ^ \s* \# \s* undef \s+ (\w+) \b /x;
                my $name = $1;
                get_and_set_cpp_visibility($name, $line);
                next;
            }

            # Everything but #defines.  All we care about are visibility
            # declarations.
            if ($line->{sub_type} ne '#define') {

                next unless $line->{sub_type} eq 'text';

                # Only comments have apidoc lines.
                next unless $line->{flat} eq "";

                next unless $line->{line} =~ / ^ =for \s+ apidoc /mx;
                process_apidoc_lines($hdr, $line->{start_line_num},
                                     split /\n/, $line->{line});
                next;
            }

            # What's left are #defines.  HeaderParser stripped off most
            # everything.
            my $name = $line->{flat};

            # Just the symbol and its definition
            $name =~ s/ ^ \s* \# \s* define \s+ //x;

            # Just the symbol, no arglist nor definition
            $name =~ s/ (?: \s | \( ) .* //x;

            # Call the subroutine with an 'undef' third parameter for symbols
            # reserved for Perl-use.  That tells it to consider these to be
            # always visible unless otherwise directed
            set_flags_visibility($name, $hdr, $line->{start_line_num}, undef)
                                  if $name =~ $names_reserved_for_perl_use_re;

            # Calculate $name's actual visibility for later use.
            my $stringified_conds = get_and_set_cpp_visibility($name, $line);

            # Done if the visibility is entirely known.
            next unless $stringified_conds =~ /[^01]/;

            # Perl creates some symbols that mimic libc symbols.  These are
            # visible everywhere and expected to be so.  Hence they should
            # remain defined.  We put them on a list of system symbols to make
            # sure this happens.
            #
            # For many symbols, this program can infer that it is in this
            # class by examining the name and context.
            #
            # One class of symbols that are like this, are ones which have
            # somewhat different names for a 64-bit version than a shorter
            # one.
            my $has_64_pattern = qr / ( HAS | USE ) _ \w* 64 /x;
            if ($stringified_conds =~ $has_64_pattern) {
                $system_symbols{$name} = 1;
                next;
            }

            # We handle two other symbol classes, both in the same way.  One
            # is where the names of things aren't standardized (or not all
            # platforms conform).  So we have created them on platforms where
            # they wouldn't otherwise exist.  The code in the header looks
            # like:
            #   #define this symbol it it isn't already defined
            #
            # An example is that platforms have different names for the S_foo
            # constants used by chmod(2) and stat(2).  There is code in perl.h
            # to define the missing names on platforms that don't have
            # particular ones, yielding a consistent set of definitions for
            # all platforms.
            #
            # The other class is when we $define a macro to override a libc
            # call with something else.  Perhaps it is a bug fix, or more
            # likely to provide reentrancy invisibly.  XS code can call a base
            # libc function, like getgrent(), and instead magically get
            # getgrent_r() when appropriate.
            #
            # To be considered system symbols, they must match the following
            # conditions (which were created by inspection of current data,
            # and which may have to be revised from time-to-time).  Note that
            # it thinks any name that is all lowercase is a libc call.
            my $pattern = qr/ ! \s* defined\($name\)/x;
            if (   (   $name !~ /[[:upper:]]/
                    || $name =~ / ^ ( [OS] _ | SIG) [[:upper:]]+ $ /x)
                && $stringified_conds =~ $pattern)
            {
                $system_symbols{$name} = 1;
                next;
            }
        }
    }   # Done with headers

    # Now look through the C and pod files.  Any preprocessor constraints in
    # these affect only the containing files, so no need to look for cpp
    # stuff.
    foreach my $pod (@c_list, @pod_list) {
        open my $pfh, "<", $pod or die "Can't open $pod: $!";
        process_apidoc_lines($pod, 1, <$pfh>);
        close $pfh or die "Can't close $pod: $!";
    }

    # Here we have examined the code base and saved the results in
    # %visibility.  There are:
    #   1)  values for C preprocessor constraints which give the actual
    #       visibility; and
    #   2)  values for the visibility flag that tells us what we want the
    #       visibility to be.
    #
    # Now reconcile these:
    #   1)  Add the symbol to a list to #undef if its flag is more restrictive
    #       than what the cpp allows, thus bringing it into compliance with
    #       the flag.
    #   2)  Warn if the cpp has made it have more limited visibility than the
    #       flag says.  There is no way that it can be made compliant with the
    #       desired visibility.

    foreach my $name (keys %visibility) {
        # Functions are dealt with elsewhere in this file by not generating a
        # short-name macro at all for them unless wanted.
        next unless $visibility{$name}{is_macro};

        my @warnings;
        my $flags_visibility = $visibility{$name}{flags};
        my $cpp_visibility = $visibility{$name}{cpp};

        # Some reserved names don't get parsed in the normal course of things,
        # such as things declared in embedvar.h, which is skipped.  But all
        # such are visible everywhere if not otherwise restricted.
        $cpp_visibility = 1 if ! defined $cpp_visibility
                            && $name =~ $names_reserved_for_perl_use_re;
        if (! defined $cpp_visibility) {

            # To get here we have a macro without having encountered its
            # #define.  This can legitimately happen when that definition is
            # in config.h, which we don't (and can't examine); or it could be
            # the result of some flaw somewhere.  But there is no real harm
            # done unless we are trying to restrict the external visibility.
            if ($flags_visibility ne '1') {
                warn "'$name' unexpectedly has no C preprocessor conditions"
                   . " for #defining it; found in "
                   . $visibility{$name}{flags_file}
                   . " line $visibility{$name}{flags_file_line_number}";
            }
            $cpp_visibility = 1;    # Assume worst case

            # (The reason we can't examine config.h is that it is not under
            # source code control, and the outputs of this program are.)
        }

        if ($cpp_visibility eq '0') {
            if (   $flags_visibility
                && ! defined $visibility{$name}{flags_implicit})
            {
                push @warnings, "'$name' cannot actually be seen outside of"
                              . " the perl core, but it is flagged as having"
                              . " '$flags_visibility' visibility; in "
                              . $visibility{$name}{flags_file}
                              . " line "
                              . $visibility{$name}{flags_file_line_number};
            }

            goto ok_but_warn_if_overridden;
        }

        if ($cpp_visibility eq '1') {
            if (! $flags_visibility) {
                # Supposed to be hidden, but isn't.  #undef it to hide it
                $always_undefs{$name} = 1;
            }
            elsif ($flags_visibility =~ /E/) {
                # Supposed to be hidden from non-extensions, but isn't.
                $non_ext_undefs{$name} = 1;
            }
            elsif ($flags_visibility eq '1') {
                goto ok_but_warn_if_overridden;
            }
            else {
                die_at_end "Unexpected flag '$flags_visibility' for '$name'"
                         . " in $visibility{$name}{flags_file}"
                         . " line "
                         . $visibility{$name}{flags_file_line_number};
            }

            next;
        }

        # The remaining legal codes are  '/' and 'E'
        if ($cpp_visibility !~ m! ^ [/E] $ !x ) {
            die_at_end "Unexpected visibility code '$cpp_visibility' for"
                     . " '$name'";
            next;
        }

        # Here #ifdef's in the code severely restrict the visibility of
        # $name, regardless of any flags.
        warn "'$name' is needlessly in %unresolved_visibility_overrides"
                                   if $unresolved_visibility_overrides{$name};
        delete $always_undefs{$name};   # No need to #undef it

        if (   $flags_visibility
            && $flags_visibility !~ /E/
            && ! defined $visibility{$name}{flags_implicit})
        {
            push @warnings, "'$name' cannot actually be seen outside of"
                          . " Perl extensions (because of #ifdef's), but"
                          . " it is flagged as having '$flags_visibility'"
                          . " visibility; in $visibility{$name}{flags_file}"
                         . " line "
                         . $visibility{$name}{flags_file_line_number};
            goto output_warnings;
        }

        next;

      ok_but_warn_if_overridden:
        push @warnings, "'$name' is needlessly listed as needing an override "
                                    if $unresolved_visibility_overrides{$name}
                                    || $needed_by_ext_re{$name}
                                    || $needed_by_ext{$name};

      output_warnings:
        for (my $i = 0; $i < @warnings; $i++) {
            my $warning = $warnings[$i];
            if ($i == @warnings - 1) {
                my $definer = $visibility{$name}{cpp_defining_object};
                if ($definer) {
                    $warning .=  " (in $definer->{source}, line"
                             .   " $definer->{start_line_num})"
                }
            }

            warn $warning;
        }
    }   # End of loop through %visibility

    # Done deciding what should be #undef'd.  But don't #undef anything found
    # in the override hashes
    my %symbol_listed_count;
    foreach my $entry (keys %system_symbols,
                       keys %needed_by_ext,
                       keys %needed_by_ext_re,
                       keys %unresolved_visibility_overrides,
                       keys %undocumented_always_visible,
                      )
    {
        $symbol_listed_count{$entry}++;
        delete $always_undefs{$entry};
    }

    foreach my $symbol (keys %symbol_listed_count) {
        next if $symbol_listed_count{$symbol} <= 1;
        die_at_end "'$symbol' is listed in more than one of the override"
                 . " lists";
    }
}

sub generate_long_names_c {
    my $longs = shift;
    my $fh = open_print_header("long_names.c");

    print $fh <<~'EOT';
/* This file is automatically generated by embed.pl.
 *
 * Its current purpose is to contain functions that are automatically
 * generated synonyms for macros for which such a synonym has been requested,
 * and for which a function is necessary.  The synonym's name is the name of
 * the macro prefixed by 'Perl_'.  In some cases, such a synonym can be
 * handled by just using a macro defined to be the short name.  Those synonyms
 * are kept out of this file by embed.pl.
 *
 * To request a synonym, add the 'p' flag to the macro's entry in embed.fnc,
 * or to its "=for apidoc" line whereever that is. */

#include "EXTERN.h"
#define PERL_IN_LONG_NAMES_C
#include "perl.h"

EOT

    for my $full_name (sort keys %{$longs}) {
        my $parser_object = $longs->{$full_name};
        next unless ref $parser_object;
        my $entry = $parser_object->{embed};

        # Store the definition of this function into @lines.  It may have to
        # have an #if guarding it.
        my @lines;
        push @lines, $parser_object->{guard} if $parser_object->{guard};

        my $name = $entry->{name};
        my $return_type = $entry->{return_type};

        # First in the actual definition is its return type
        push @lines, $return_type;

        # Then the function name, and prototype
        push @lines, "$full_name(";
        $lines[-1] .= "pTHX" unless $entry->{flags} =~ /T/;
        if ($entry->{args}->@*) {
            $lines[-1] .=  '_ ' unless $entry->{flags} =~ /T/;
            $lines[-1] .=  join ", ", @{$entry->{args}};
        }
        $lines[-1] .=  ")";

        # Then the beginning of its definition
        push @lines, <<~EOT;
            {
                PERL_ARGS_ASSERT_\U$name;
            EOT

        # Then the definition, which is to just call the short name macro.
        # Since this is compiled as part of the core, the short name is
        # available
        push @lines, " " x 4;
        $lines[-1] .= "return " if $return_type ne 'void';
        $lines[-1] .= "$name(";

        # For each parameter, we need just its name.  This assumes the
        # parameter name is the final \w+ chars
        $lines[-1] .= join ", ", map { s/ .*? (\w+) $ /$1/rx }
                                        @{$entry->{args}} if @{$entry->{args}};
        $lines[-1] .= ");";

        # Finally the closing brace< and any guard #endif
        push @lines, "}";
        push @lines, "#endif" if $parser_object->{guard};

        # Replace what the HeaderLine object thinks is the output line with
        # the ones just calculated.
        $parser_object->{line} = join "\n", @lines;

        # And get HeaderParser to surround that with any #if's that it found
        # when parsing embed.fnc
        my $hp= HeaderParser->new();
        my $group = $hp->group_content([$parser_object]);
        print $fh $hp->lines_as_str($group), "\n";;
    }

    read_only_bottom_close_and_rename($fh) if ! $error_count;
}

sub update_headers {
    my ($all, $api, $ext, $core) = setup_embed(); # see regen/embed_lib.pl
    generate_proto_h($all);
    die_at_end "$unflagged_pointers pointer arguments to clean up\n"
                                                       if $unflagged_pointers;
    find_undefs($all);
    generate_embed_h($all, $api, $ext, $core);
    generate_long_names_c(\%need_longs);
    generate_embedvar_h();
    die "$error_count errors found" if $error_count;
}

update_headers() unless caller;

# ex: set ts=8 sts=4 sw=4 et:
