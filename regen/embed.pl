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
#
# Accepts the standard regen_lib -q and -v args.
#
# This script is normally invoked from regen.pl.
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

my @az = ('a'..'z');

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
# list.
my %skip_files;
$skip_files{$_} = 1 for qw(
                            charclass_invlists.inc
                            config.h
                            embed.h
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

# This is a list of symbols that are not documented to be available for
# modules to use, but are nevertheless currently not kept by embed.h from
# being visible to the world.
#
# Strive to make this list empty.
#
# The list does not include symbols that we have documented as being reserved
# for perl's use, namely those that begin with 'PL_' or contain qr/perl/i.
# There are two parts of the list; the second part contains the symbols which
# have a trailing underscore; the first part those without.
#
# For all modules that aren't deliberating using particular names, all the
# other symbols on it are namespace pollutants.

my @unresolved_visibility_overrides = qw(
    _
    ABORT
    ABS_IV_MIN
    ALIGNED_TYPE
    ALIGNED_TYPE_NAME
    ALL_PARENS_COUNTED
    ALWAYS_WARN_SUPER
    AMG_CALLun
    AMG_CALLunary
    AMGfallNEVER
    AMGfallNO
    AMGfallYES
    AMGf_assign
    AMGf_noleft
    AMGf_noright
    AMGf_numarg
    AMGf_numeric
    AMGf_unary
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
    BSD_SETPGRP
    BYTES_REMAINING_IN_WORD
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
    CLONEf_CLONE_HOST
    CLONEf_COPY_STACKS
    CLONEf_JOIN_IN
    CLONEf_KEEP_PTR_TABLE
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
    cophh_exists_pv
    cophh_exists_pvs
    cophh_exists_sv
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
    DEBUG_DB_RECURSE_FLAG
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
    DEBUG_MASK
    DEBUG_m_FLAG
    DEBUG_M_FLAG
    DEBUG_m_TEST
    DEBUG_M_TEST
    DEBUG_o
    DEBUG_o_FLAG
    DEBUG_o_TEST
    DEBUG_p
    DEBUG_P
    DEBUG_PEEP
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
    DEBUG_RExC_seen
    DEBUG_r_FLAG
    DEBUG_R_FLAG
    DEBUG_r_TEST
    DEBUG_R_TEST
    DEBUG_s
    DEBUG_S
    DEBUG_SCOPE
    DEBUG_s_FLAG
    DEBUG_S_FLAG
    DEBUG_SHOW_STUDY_FLAG
    DEBUG_s_TEST
    DEBUG_S_TEST
    DEBUG_STUDYDATA
    DEBUG_t
    DEBUG_T
    DEBUG_t_FLAG
    DEBUG_T_FLAG
    DEBUG_TOP_FLAG
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
    DEFAULT_PAT_MOD
    DEFERRED_COULD_BE_OFFICIAL_MARKERc
    DEFERRED_COULD_BE_OFFICIAL_MARKERs
    DEFERRED_USER_DEFINED_INDEX
    del_body_by_type
    DEL_NATIVE
    DEPENDS_PAT_MOD
    DEPENDS_PAT_MODS
    DEPENDS_SEMANTICS
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
    do_aexec
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
    ELEMENT_RANGE_MATCHES_INVLIST
    EMBEDMYMALLOC
    EMULATE_THREAD_SAFE_LOCALES
    ENDGRENT_R_HAS_FPTR
    ENDPWENT_R_HAS_FPTR
    ENV_INIT
    environ
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
    first_upper_bit_set_byte_number
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
    FROM_INTERNAL_SIZE
    F_sin_amg
    F_sqrt_amg
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
    HAS_GROUP
    HAS_IOCTL
    HAS_KILL
    HAS_NONLATIN1_FOLD_CLOSURE
    HAS_NONLATIN1_SIMPLE_FOLD_CLOSURE
    HAS_PASSWD
    HAS_POSIX_2008_LOCALE
    HAS_PTHREAD_UNCHECKED_GETSPECIFIC_NP
    HAS_UTIME
    HAS_WAIT
    hasWARNBIT
    HASWIDTH
    HE_ARENA_ROOT_IX
    HEK_BASESIZE
    HeKEY_hek
    HeKEY_sv
    HEKfARG
    HeKFLAGS
    HEK_FLAGS
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
    htonl
    htons
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
    INCMARK
    INFNAN_NV_U8_DECL
    INFNAN_U8_NV_DECL
    init_os_extras
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
    INT32_MIN
    INT_64_T
    INT_PAT_MODS
    IN_UNI_8_BIT
    IN_UTF8_CTYPE_LOCALE
    IN_UTF8_TURKIC_LOCALE
    INVLIST_INDEX
    IoANY
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
    isIDCONT_lazy_if_safe
    isIDCONT_LC_utf8
    isIDCONT_uni
    isIDFIRST_lazy_if_safe
    isIDFIRST_LC_utf8
    isIDFIRST_uni
    IS_IN_SOME_FOLD_L1
    is_LARGER_NON_CHARS_utf8
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
    IS_NON_FINAL_FOLD
    isnormal
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
    isQUOTEMETA
    is_QUOTEMETA_high
    isREGEXP
    IS_SAFE_PATHNAME
    IS_SAFE_SYSCALL
    is_SHORTER_NON_CHARS_utf8
    isSPACE_LC_utf8
    isSPACE_uni
    is_SPACE_utf8_safe_backwards
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
    IV_MAX_P1
    JE_OLD_STACK_HWM_restore
    JE_OLD_STACK_HWM_save
    JE_OLD_STACK_HWM_zero
    JMPENV_BOOTSTRAP
    JMPENV_POP
    kBINOP
    kCOP
    KEEPCOPY_PAT_MOD
    KEEPCOPY_PAT_MODS
    KELVIN_SIGN
    KERNEL
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
    LC_NUMERIC_UNLOCK
    LDBL_DIG
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
    LOCALTIME_LOCK
    LOCALTIME_UNLOCK
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
    MAX_CHARSET_NAME_LENGTH
    MAX_FOLD_FROMS
    MAX_LEGAL_CP
    MAX_MATCHES
    MAXO
    MAX_PORTABLE_UTF8_TWO_BYTE
    MAX_PRINT_A
    MAX_SAVEt
    MAX_UNICODE_UTF8
    MAX_UNICODE_UTF8_BYTES
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
    MEM_LOG_DEL_SV
    MEM_LOG_NEW_SV
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
    MUTEX_INIT_NEEDS_MUTEX_ZEROED
    my_binmode
    MY_CXT_INDEX
    MY_CXT_INIT_ARG
    MY_CXT_INIT_INTERP
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
    newRV_inc
    new_SV
    NEWSV
    NEW_VERSION
    new_XNV
    new_XPV
    new_XPVIV
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
    NON_OTHER_COUNT
    NONV
    NO_POSIX_2008_LOCALE
    NORETURN_FUNCTION_END
    NORMAL
    NOTE3
    NOT_REACHED
    ntohi
    ntohl
    ntohs
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
    NV_LITTLE_ENDIAN
    NV_MANT_DIG
    NV_MAX
    NV_MAX_10_EXP
    NV_MAX_EXP
    NV_MIN
    NV_MIN_10_EXP
    NV_MIN_EXP
    NV_MIX_ENDIAN
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
    OP_SIBLING
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
    OPpEARLY_CV
    OPpEMPTYAVHV_IS_HV
    OPpENTERSUB_AMPER
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
    OPpPARAM_IF_FALSE
    OPpPARAM_IF_UNDEF
    OPpPV_IS_UTF8
    OPpREFCOUNTED
    OPpREPEAT_DOLIST
    OPpREVERSE_INPLACE
    OPpRV2HV_ISKEYS
    OPpSELF_IN_PAD
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
    PREV_RANGE_MATCHES_INVLIST
    PRINTF_FORMAT_NULL_OK
    PRIVSHIFT
    ProgLen
    pthread_addr_t
    pthread_attr_init
    pthread_condattr_default
    pthread_create
    PTHREAD_GETSPECIFIC
    PTHREAD_GETSPECIFIC_INT
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
    pTHX__VALUE
    pTHX_VALUE
    PUSH_MULTICALL_FLAGS
    PUSHSTACK
    PUSHSTACKi
    PUSHSTACK_INIT_HWM
    PUSHTARG
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
    RExC_parse_advance
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
    SAVEt_PADSV_AND_MORTALIZE
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
    SBOX32_MIX3
    SBOX32_MIX4
    SBOX32_STATE_BITS
    SBOX32_STATE_BYTES
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
    Semctl
    semun
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
    setregid
    setreuid
    SETs
    SET_SVANY_FOR_BODYLESS_IV
    SET_SVANY_FOR_BODYLESS_NV
    SETTARG
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
    SHUTDOWN_TERM
    SHY_NATIVE
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
    socketpair
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
    SvEND_set
    SvENDx
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
    SvGMAGICAL
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
    SvIVx
    SvIVXx
    SvLENx
    SvMAGIC
    SvMAGICAL
    SvMAGICAL_off
    SvMAGICAL_on
    SV_MUTABLE_RETURN
    SvNIOK_nog
    SvNIOK_nogthink
    SvNOK_nog
    SvNOK_nogthink
    SvNOKp_on
    SvNVx
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
    SvRMAGICAL
    SvRMAGICAL_off
    SvRMAGICAL_on
    SvRV_const
    SvRVx
    SvSCREAM
    SvSCREAM_off
    SvSCREAM_on
    SvSetSV_and
    SvSetSV_nosteal_and
    SVs_GMG
    SvSHARED_HEK_FROM_PV
    SvSMAGICAL
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
    SvUVx
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
    THREAD_CREATE_NEEDS_STACK
    tI
    toCTRL
    toFOLD_LC
    toFOLD_uni
    TO_INTERNAL_SIZE
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
    U8TO32_LE
    U8TO64_LE
    U_I
    UINT
    U_L
    UNICODE_ALLOW_ANY
    UNICODE_ALLOW_SUPER
    UNICODE_ALLOW_SURROGATE
    UNICODE_BYTE_ORDER_MARK
    UNICODE_DOT_DOT_VERSION
    UNICODE_DOT_VERSION
    UNICODE_GOT_NONCHAR
    UNICODE_GOT_SUPER
    UNICODE_GOT_SURROGATE
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
    USE_ENVIRON_ARRAY
    USE_GRENT_BUFFER
    USE_GRENT_FPTR
    USE_GRENT_PTR
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
    UTF8_ALLOW_ANY
    UTF8_ALLOW_ANYUV
    UTF8_ALLOW_DEFAULT
    UTF8_ALLOW_FE_FF
    UTF8_ALLOW_FFFF
    UTF8_ALLOW_LONG_AND_ITS_VALUE
    UTF8_ALLOW_SURROGATE
    UTF8_DIE_IF_MALFORMED
    UTF8_DISALLOW_ABOVE_31_BIT
    UTF8_DISALLOW_FE_FF
    UTF8_EIGHT_BIT_HI
    UTF8_EIGHT_BIT_LO
    UTF8_FORCE_WARN_IF_MALFORMED
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
    VXS_RETURN_M_SV
    VXSp
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
    XTENDED_PAT_MOD
    xuv_uv
    xV_FROM_REF
    YYEMPTY
    YYSTYPE_IS_TRIVIAL
    ZAPHOD32_FINALIZE
    ZAPHOD32_MIX
    ZAPHOD32_SCRAMBLE32
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
    CC_MAGICAL_
    CC_mask_
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
    DFA_RETURN_FAILURE_
    DFA_RETURN_SUCCESS_
    DFA_TEASE_APART_FF_
    EXTEND_NEEDS_GROW_
    EXTEND_SAFE_N_
    FAIL_
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
    invlist_intersection_complement_2nd_
    invlist_union_complement_2nd_
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
    MEM_WRAP_NEEDS_RUNTIME_CHECK_
    MEM_WRAP_WILL_WRAP_
    msbit_pos_uintmax_
    NOT_IN_NUMERIC_STANDARD_
    NOT_IN_NUMERIC_UNDERLYING_
    NV_BODYLESS_UNION_
    o1_
    OFFUNISKIP_helper_
    PADNAME_BASE_
    PLATFORM_SYS_INIT_
    PLATFORM_SYS_TERM_
    pTHXo_
    pTHX__VALUE_
    pTHX_VALUE_
    pTHXx_
    RXf_PMf_CHARSET_SHIFT_
    RXf_PMf_SHIFT_COMPILETIME_
    RXf_PMf_SHIFT_NEXT_
    SAFE_FUNCTION__
    SBOX32_CASE_
    shifted_octet_
    STATIC_ASSERT_STRUCT_BODY_
    STATIC_ASSERT_STRUCT_NAME_
    SV_HEAD_
    SV_HEAD_DEBUG_
    SV_HEAD_UNION_
    toFOLD_utf8_flags_
    toLOWER_utf8_flags_
    TOO_LATE_FOR_
    toTITLE_utf8_flags_
    toUPPER_utf8_flags_
    type1_
    UNI_DISPLAY_TR_
    UNISKIP_BY_MSB_
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
    UTF8_IS_SUPER_NO_CHECK_
    UTF8_NO_CONFIDENCE_IN_CURLEN_
    UTF8_NO_CONFIDENCE_IN_CURLEN_BIT_POS_
    utf8_safe_assert_
    UTF8_WARN_NONCHAR_BIT_POS_
    UTF8_WARN_SUPER_BIT_POS_
    UTF8_WARN_SURROGATE_BIT_POS_
    UTF_FIRST_CONT_BYTE_110000_
    UTF_START_BYTE_110000_
    WARN_HELPER_
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
    INT32_MIN
    INT64_MIN
    LDBL_DIG
    O_CREAT
    O_RDWR
    O_WRONLY
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
);

# This is a list of symbols that are needed by various ext/ modules, and are
# not documented.  They become undefined for any other modules.
my @needed_by_ext = qw(
);

my %unresolved_visibility_overrides;
$unresolved_visibility_overrides{$_} = 1 for @unresolved_visibility_overrides;

my %system_symbols;
$system_symbols{$_} = 1 for @system_symbols;

my %needed_by_ext_re;
$needed_by_ext_re{$_} = 1 for @needed_by_ext_re;

my %needed_by_ext;
$needed_by_ext{$_} = 1 for @needed_by_ext;

# Keep lists of symbols to undef under various conditions.  We can initialize
# the two ones for perl extensions with the lists above.
my %always_undefs;
my %non_ext_re_undefs = %needed_by_ext_re;
my %non_ext_undefs = %needed_by_ext;

# See database of global and static function prototypes in embed.fnc
# This is used to generate prototype headers under various configurations,
# export symbols lists for different platforms, and macros to provide an
# implicit interpreter context argument.
#

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

        my ($flags, $retval, $plain_func, $args, $assertions ) =
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
                                             && ($flags !~ /$C_required_flags/

                                                # Notwithstanding the
                                                # above, if the name won't
                                                # clash with a user name,
                                                # it's ok.
                                             && $plain_func !~ /^[Pp]erl/);


        my @nonnull;
        my $args_assert_line = ( $flags !~ /m/ );
        my $has_depth = ( $flags =~ /W/ );
        my $has_context = ( $flags !~ /T/ );
        my $never_returns = ( $flags =~ /r/ );
        my $binarycompat = ( $flags =~ /b/ );
        my $has_mflag = ( $flags =~ /m/ );
        my $is_malloc = ( $flags =~ /a/ );
        my $can_ignore = $flags !~ /[RP]/ && !$is_malloc;
        my $extensions_only = ( $flags =~ /E/ );
        my @asserts;
        my $func;

        if (! $can_ignore && $retval eq 'void') {
            warn "It is nonsensical to require the return value of a void"
               . " function ($plain_func) to be checked";
        }

        if ($flags =~ /[AC]/ && $flags =~ /([EX])/) {
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
            next unless $flags =~ /[ACE]/;

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
                    'S' => 'STATIC',
                    's' => 'STATIC',
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
                                    && $flags =~ /[AC]/
                                    && $plain_func !~ /[Pp]erl/;

            if ($never_returns) {
                $retval = "PERL_CALLCONV_NO_RET $retval";
            }
            else {
                $retval = "PERL_CALLCONV $retval";
            }
        }

        $func = full_name($plain_func, $flags);

        $ret = "";
        $ret .= "$retval\n";
        $ret .= "$func(";
        if ( $has_context ) {
            $ret .= @$args ? "pTHX_ " : "pTHX";
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
                    my $equal = ""; # set to "=" if can be equal to previous
                                    # pointer, empty if not
                    if ($arg =~ s/ \b ( EPTRgt | EPTRge | MPTR | SPTR ) \b //x)
                    {
                        my $name = $1;
                        $ptr_type = substr($name, 0, 1);
                        $equal = "=" if $ptr_type eq 'M'
                                     or (   $ptr_type eq 'E'
                                         && substr($name, -1, 1) eq 'e');
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
                         . " EPTRge, EPTRgt, MPTR, SPTR), NULLOK, or NZ"
                                               if 0 + $nn + $nz + $nullok > 1;

                    push( @nonnull, $n ) if $nn;

                    # A non-pointer shouldn't have a pointer-related modifier.
                    # But typedefs may be pointers without our knowing it, so
                    # we can't check for non-pointer issues.  We can only
                    # check for the case where the argument is definitely a
                    # pointer.
                    if ($args_assert_line && $arg =~ /\*/) {
                        if ($nn + $nullok == 0) {
                            warn "$func: $arg needs one of: NN, EPTRge,"
                               . " EPTRgt, MPTR, SPTR, or NULLOK\n";
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
                        && ($temp_arg !~ /\w+\s+(\w+)(?:\[\d+\])?\s*$/) ) {
                        die_at_end "$func: $arg ($n) doesn't have a name\n";
                    }
                    my $argname = $1;

                    if (defined $argname && (! $has_mflag || $binarycompat)) {
                        if ($nn||$nz) {
                            push @asserts, "assert($argname)";
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
                                          argname => $argname,
                                          equal   => $equal,
                                          deref   => $derefs,
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
                            #               },
                            #       'E' => {
                            #               'equal' => '',
                            #               'argname' => 'strend',
                            #               'deref' => ''
                            #               },
                            #       'S' => {
                            #               'equal' => '',
                            #               'deref' => '',
                            #               'argname' => 'strbeg'
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

                    my $lower = $string->{$i->[0]} or next;
                    my $upper = $string->{$i->[1]} or next;

                    # This reduces to either;
                    #   assert(lower < upper);
                    # or
                    #   assert(lower <= upper);
                    #
                    # There might also be some derefences, like **lower
                    push @asserts, "assert("
                                        . "$lower->{deref}$lower->{argname}"
                                        . " <$upper->{equal} "
                                        . "$upper->{deref}$upper->{argname}"
                                        . ")";
                }
            }

            $ret .= join ", ", @$args;
        }
        else {
            $ret .= "void" if !$has_context;
        }
        $ret .= " comma_pDEPTH" if $has_depth;
        $ret .= ")";

        push @asserts, @$assertions if $assertions;

        my @attrs;
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
            $ret .= "\n";
            $ret .= join( "\n", map { (" " x 8) . $_ } @attrs );
        }
        $ret .= ";";
        $ret = "/* $ret */" if $has_mflag;

        # Hide the prototype from non-authorized code.  This acts kind of like
        # __attribute__visibility__("hidden") for cases where that can't be
        # used.
        $ret = "#${ind}if defined(PERL_CORE) || defined(PERL_EXT)\n"
             . $ret
             . " \n#${ind}endif"
          if $extensions_only;

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
        if ($_->{type} ne "content") {
            $lines .= $_->{line};
            next;
        }
        my $level= $_->{level};
        my $embed= $_->{embed} or next;
        my ($flags,$retval,$func,$args) =
                                   @{$embed}{qw(flags return_type name args)};

        # Macros with [oO] don't appear without a [Pp]erl_ prefix, so nothing
        # to undef
        if ($flags =~ /m/ && $flags !~ /[oO]/) {
            if ($flags !~ /[ACE]/) {    # No external visibility
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

            # Yields
            #   #define Perl_func  func
            # which works when there is no thread context.
            $ret = indent_define($full_name, $func, $ind);

            if ($flags !~ /[T]/) {

                # But when there is the possibility of a thread context
                # parameter, $ret works only on non-threaded builds
                my $no_thread_full_define = $ret;

                # And we have to do more when there are threads.  First,
                # convert the input argument list to 'a', 'b' ....  This keeps
                # us from having to worry about all the extra stuff in the
                # input list; stuff like the type declarations, things like
                # NULLOK, and pointers '*'.
                my $argname = 'a';
                my @stripped_args;
                push @stripped_args, $argname++ for $args->@*;
                my $arglist = join ",", @stripped_args;

                # In the threaded case, the Perl_ form is expecting an aTHX
                # first argument.  Use mTHX to match that, which isn't passed
                # on to the short form name, as that is expecting an implicit
                # aTHX.  The non-threaded case just uses what we generated
                # above for the /T/ flag case.
                my $mTHX_ = "mTHX";
                $mTHX_ .= ',' if $arglist ne "";
                $ret = "#${ind}ifdef USE_THREADS\n"
                     . "#${ind}  define $full_name($mTHX_$arglist)"
                     .           "  $func($arglist)\n"
                     . "#${ind}else\n"
                     . "$ind  $no_thread_full_define" # No \n because no chomp
                     . "#${ind}endif\n";
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

sub recurse_conds {

    #  Look through the list of conditionals that HeaderParser generates,
    #  looking for occurrences of the regex $pattern, returning true if found;
    #  false otherwise.

    my $status = 0;
    my ($pattern, @conds) = @_;
    for my $this_cond (@conds) {

        # Recurse if necessary
        if (ref $this_cond eq 'ARRAY') {
            $status |= recurse_conds($pattern, $this_cond->@*);
            return $status if $status;  # Early return if found
        }
        else {
            $status |= $this_cond =~ $pattern;
            return $status if $status;  # Early return if found
        }
    }

    return 0;
}

my %visibility;

sub process_apidoc_lines {

    # Look through the input array of lines for ones that can declare the
    # visibility of a symbol, and add those that are visible externally to
    # that list; and those that are visible to perl extensions to that list

    my $group_flags;
    for my $individual_line (@_) {
        next unless $individual_line =~
                        m/ ^=for \s+ apidoc (\b | _defn | _item) \s* (.+) /x;
        my $type = $1;

        # A full-blown declaration has all these fields
        my ($flags, $return_type, $name, @rest) = split /\s*\|\s*/, $2;

        # But some lines look like '=for apidoc foo' where the rest of the
        # data comes from elsewhere.  For these, shift.
        if (! defined $return_type) {
            $name = $flags;
            $flags = "";
        }

        # These declarations may come in groups with the first line being
        # 'apidoc', and the remaining ones 'apidoc_item'.  The flags parameter
        # of the 'apidoc' line applies to the rest, though those may add flags
        # individually.
        if ($type ne  "_item" ) {
            $group_flags = $flags;
        }
        elsif ($flags) {
            $flags .= $group_flags;
        }
        else {
            $flags = $group_flags;
        }

        # If no flag indicates any external visibility, we are done with this
        # one.
        $flags =~ s/[^ACE]//g;
        next unless $flags;

        #next if defined $needed_by_ext{$name};
        #next if defined $needed_by_ext_re{$name};

        #die_at_end "${name}'s visibility is declared more than once"
                                                #if defined $visibility{$name};
        $visibility{$name} = $flags;
    }
}

sub find_undefs {

    # Find all the #defines that are visible to modules and which aren't
    # marked as such nor whose names indicate they are reserved for Perl's
    # use.  These are the symbols to #undef to prevent that visibility
    #
    # First examine the passed in data from embed.fnc;
    my $all = shift;
    foreach my $entry ($all->@*) {
        next unless $entry->embed;
        my $flags = $entry->embed->{flags};
        $flags =~ s/[^ACE]//g;
        next unless $flags;     # No visibility
        $visibility{$entry->embed->{name}} = $flags;
    }

    # Then examine every top-level header.  And we also examine the top
    #  level dot c files looking for symbols that are supposed to be visible.
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


    # A symbol can't be visible if it is guarded by #ifdef's that evaluate to
    # false.
    #
    # One type of such #ifdef follows the convention in perl's source code
    # that a C file, 'foo.c', will #define a symbol at the beginning named
    # PERL_IN_FOO_C.  And some otherwise global symbols in header files will
    # be protected from being visible from outside foo.c by
    #   #ifdef PERL_IN_FOO_C
    #   #  define x
    #   #  define y
    #   #    ...
    #   #endif
    #
    # 'x', 'y', ... need not be #undefined, as they aren't visible outside the
    # C files that are permitted to see them.  Below we look at every symbol
    # that has potential global scope to see if there are #ifdef's that
    # conditionally #define it and which evaluate to false.  We know that all
    # the PERL_IN_FOO_C symbols will be false.  reduce_conds() looks at the
    # totality of the #ifdefs guarding a symbol and determines if they
    # evaluate, as a whole, to false or not.  We don't know the value of many
    # of the conditions, but generally, the ones that guard visibility will be
    # enough to rule out a symbol being globally visible.
    my %constraints;
    for my $c (@c_list) {
        my $c_prime = $c =~ s/[.]/_/r;
        $constraints{ "PERL_IN_\U$c_prime" } = 0;
    }

    # There are also these three symbols that guard visibility.  A symbol that
    # is visible when all three are 0, is globally visible.
    $constraints{PERL_CORE} = 0;
    $constraints{PERL_EXT} = 0;
    $constraints{PERL_EXT_RE_BUILD} = 0;

    # Match any of these.  HeaderParser creates this canonical form for all
    # conditionals.
    my $constraints_re = join "|", keys %constraints;
    $constraints_re = qr/ \b defined \( ( $constraints_re ) \) /x;

    # There are a few cases where we redefine a system function to use the
    # 64-bit equivalent one that has a different name.  They currenty all look
    # like this.  These symbols would show up as #defines that shouldn't have
    # external visibility.
    my $has_64_pattern = qr / ( HAS | USE ) _ \w* 64 /x;

    # Now look through all the header files for symbols that are visible to
    # the outside world, and shouldn't be.
    foreach my $hdr (@header_list) {

        # Parse the header
        my $lines = HeaderParser->new()->read_file($hdr)->lines();
        foreach my $line ($lines->@*) {

            # We are here looking only for #defines and visibility
            # declarations
            next unless $line->{type} eq 'content';

            # First, for #defines.
            if ($line->{sub_type} eq '#define') {

                # HeaderParser stripped off most everything.
                my $name = $line->{flat};

                # Just the symbol and its definition
                $name =~ s/ ^ \s* \# \s* define \s+ //x;

                # Just the symbol, no arglist nor definition
                $name =~ s/ (?: \s | \( ) .* //x;

                # These are reserved for Perl's use, so not a problem.
                next if $name =~ / ^ PL_ /x;
                next if $name =~ /perl/i;

                next unless $line->reduce_conds($constraints_re,
                                                \%constraints);

                # Often perl has code to make sure various symbols that are
                # always expected by the system to be defined, in fact are.
                # These don't constitute namespace pollution.  So, if perl
                # defines a symbol only if it already isn't defined, we add it
                # to the list of system symbols
                my $pattern = qr/ ! \s* defined\($name\)/x;
                if (   recurse_conds($pattern, $line->{cond}->@*)
                    || recurse_conds($has_64_pattern, $line->{cond}->@*))
                {
                    $system_symbols{$name} = 1;
                }
                else {
                    $always_undefs{$name} = 1;
                }
            }
            else {

                # Otherwise check for a visibility declaration.
                next unless $line->{sub_type} eq 'text';

                # Only comments have apidoc lines.
                next unless $line->{flat} eq "";

                next unless $line->{line} =~ / ^ =for \s+ apidoc /mx;
                process_apidoc_lines(split /\n/, $line->{line});
            }
        }
    }   # Done with headers

    # Now look through the C and pod files
    foreach my $pod (@c_list, @pod_list) {
        open my $pfh, "<", $pod or die "Can't open $pod: $!";
        process_apidoc_lines(<$pfh>);
        close $pfh or die "Can't close $pod: $!";
    }

    # Here, have found all the externally visible macro definitions.  We will
    # undef all of them that aren't expected to be visible and aren't
    # otherwise needed to be visible.
    foreach my $entry (keys %system_symbols,
                            %needed_by_ext,
                            %needed_by_ext_re,
                            %visibility,
                            %unresolved_visibility_overrides
                      )
    {
        delete $always_undefs{$entry};
    }

}

sub update_headers {
    my ($all, $api, $ext, $core) = setup_embed(); # see regen/embed_lib.pl
    generate_proto_h($all);
    die_at_end "$unflagged_pointers pointer arguments to clean up\n"
                                                       if $unflagged_pointers;
    find_undefs($all);
    generate_embed_h($all, $api, $ext, $core);
    generate_embedvar_h();
    die "$error_count errors found" if $error_count;
}

update_headers() unless caller;

# ex: set ts=8 sts=4 sw=4 et:
