#ifndef __ObjXSub_h__
#define __ObjXSub_h__

/* Varibles */ 
#undef  Argv
#define Argv			pPerl->Perl_Argv
#undef  Cmd
#define Cmd			pPerl->Perl_Cmd
#undef  DBcv
#define DBcv			pPerl->Perl_DBcv
#undef  DBgv
#define DBgv			pPerl->Perl_DBgv
#undef  DBline
#define DBline			pPerl->Perl_DBline
#undef  DBsignal
#define DBsignal		pPerl->Perl_DBsignal
#undef  DBsingle
#define DBsingle		pPerl->Perl_DBsingle
#undef  DBsub
#define DBsub			pPerl->Perl_DBsub
#undef  DBtrace
#define DBtrace			pPerl->Perl_DBtrace
#undef  No
#define No			pPerl->Perl_No
#undef  Sv
#define Sv			pPerl->Perl_Sv
#undef  Xpv
#define Xpv			pPerl->Perl_Xpv
#undef  Yes
#define Yes			pPerl->Perl_Yes
#undef  amagic_generation
#define amagic_generation	pPerl->Perl_amagic_generation
#undef  ampergv
#define ampergv			pPerl->Perl_ampergv
#undef  an
#define an			pPerl->Perl_an
#undef  archpat_auto
#define archpat_auto		pPerl->Perl_archpat_auto
#undef  argvgv
#define argvgv			pPerl->Perl_argvgv
#undef  argvoutgv
#define argvoutgv		pPerl->Perl_argvoutgv
#undef  av_fetch_sv
#define av_fetch_sv         pPerl->av_fetch_sv
#undef  basetime
#define basetime		pPerl->Perl_basetime
#undef  beginav
#define beginav			pPerl->Perl_beginav
#undef  bodytarget
#define bodytarget		pPerl->Perl_bodytarget
#undef  bostr
#define bostr			pPerl->Perl_bostr
#undef  bufend
#define bufend			pPerl->Perl_bufend
#undef  bufptr
#define bufptr			pPerl->Perl_bufptr
#undef  byterun
#define byterun			pPerl->Perl_byterun
#undef  cddir
#define cddir			pPerl->Perl_cddir
#undef  chopset
#define chopset			pPerl->Perl_chopset
#undef  collation_ix
#define collation_ix		pPerl->Perl_collation_ix
#undef  collation_name
#define collation_name		pPerl->Perl_collation_name
#undef  collation_standard
#define collation_standard	pPerl->Perl_collation_standard
#undef  collxfrm_base
#define collxfrm_base		pPerl->Perl_collxfrm_base
#undef  collxfrm_mult
#define collxfrm_mult		pPerl->Perl_collxfrm_mult
#undef  colors
#define colors			pPerl->Perl_colors
#undef  colorset
#define colorset		pPerl->Perl_colorset
#undef  compcv
#define compcv			pPerl->Perl_compcv
#undef  compiling
#define compiling		pPerl->Perl_compiling
#undef  comppad
#define comppad			pPerl->Perl_comppad
#undef  comppad_name
#define comppad_name		pPerl->Perl_comppad_name
#undef  comppad_name_fill
#define comppad_name_fill	pPerl->Perl_comppad_name_fill
#undef  comppad_name_floor
#define comppad_name_floor	pPerl->Perl_comppad_name_floor
#undef  cop_seqmax
#define cop_seqmax		pPerl->Perl_cop_seqmax
#undef  copline
#define copline			pPerl->Perl_copline
#undef  cryptseen
#define cryptseen		pPerl->Perl_cryptseen
#undef  cshlen
#define cshlen			pPerl->Perl_cshlen
#undef  cshname
#define cshname			pPerl->Perl_cshname
#undef  curcop
#define curcop			pPerl->Perl_curcop
#undef  curcopdb
#define curcopdb		pPerl->Perl_curcopdb
#undef  curinterp
#define curinterp		pPerl->Perl_curinterp
#undef  curpad
#define curpad			pPerl->Perl_curpad
#undef  curpm
#define curpm			pPerl->Perl_curpm
#undef  curstack
#define curstack		pPerl->Perl_curstack
#undef  curstackinfo
#define curstackinfo		pPerl->Perl_curstackinfo
#undef  curstash
#define curstash		pPerl->Perl_curstash
#undef  curstname
#define curstname		pPerl->Perl_curstname
#undef  curthr
#define curthr			pPerl->Perl_curthr
#undef  dbargs
#define dbargs			pPerl->Perl_dbargs
#undef  debdelim
#define debdelim		pPerl->Perl_debdelim
#undef  debname
#define debname			pPerl->Perl_debname
#undef  debstash
#define debstash		pPerl->Perl_debstash
#undef  debug
#define debug			pPerl->Perl_debug
#undef  defgv
#define defgv			pPerl->Perl_defgv
#undef  defoutgv
#define defoutgv		pPerl->Perl_defoutgv
#undef  defstash
#define defstash		pPerl->Perl_defstash
#undef  delaymagic
#define delaymagic		pPerl->Perl_delaymagic
#undef  diehook
#define diehook			pPerl->Perl_diehook
#undef  dirty
#define dirty			pPerl->Perl_dirty
#undef  dlevel
#define dlevel			pPerl->Perl_dlevel
#undef  dlmax
#define dlmax			pPerl->Perl_dlmax
#undef  do_undump
#define do_undump		pPerl->Perl_do_undump
#undef  doextract
#define doextract		pPerl->Perl_doextract
#undef  doswitches
#define doswitches		pPerl->Perl_doswitches
#undef  dowarn
#define dowarn			pPerl->Perl_dowarn
#undef  dumplvl
#define dumplvl			pPerl->Perl_dumplvl
#undef  e_script
#define e_script		pPerl->Perl_e_script
#undef  egid
#define egid			pPerl->Perl_egid
#undef  endav
#define endav			pPerl->Perl_endav
#undef  envgv
#define envgv			pPerl->Perl_envgv
#undef  errgv
#define errgv			pPerl->Perl_errgv
#undef  error_count
#define error_count		pPerl->Perl_error_count
#undef  euid
#define euid			pPerl->Perl_euid
#undef  eval_cond
#define eval_cond		pPerl->Perl_eval_cond
#undef  eval_mutex
#define eval_mutex		pPerl->Perl_eval_mutex
#undef  eval_owner
#define eval_owner		pPerl->Perl_eval_owner
#undef  eval_root
#define eval_root		pPerl->Perl_eval_root
#undef  eval_start
#define eval_start		pPerl->Perl_eval_start
#undef  evalseq
#define evalseq			pPerl->Perl_evalseq
#undef  exitlist
#define exitlist            pPerl->exitlist
#undef  exitlistlen
#define exitlistlen         pPerl->exitlistlen
#undef  expect
#define expect			pPerl->Perl_expect
#undef  extralen
#define extralen		pPerl->Perl_extralen
#undef  fdpid
#define fdpid			pPerl->Perl_fdpid
#undef  filemode
#define filemode		pPerl->Perl_filemode
#undef  firstgv
#define firstgv			pPerl->Perl_firstgv
#undef  forkprocess
#define forkprocess		pPerl->Perl_forkprocess
#undef  formfeed
#define formfeed		pPerl->Perl_formfeed
#undef  formtarget
#define formtarget		pPerl->Perl_formtarget
#undef  generation
#define generation		pPerl->Perl_generation
#undef  gensym
#define gensym			pPerl->Perl_gensym
#undef  gid
#define gid			pPerl->Perl_gid
#undef  globalstash
#define globalstash		pPerl->Perl_globalstash
#undef  he_root
#define he_root			pPerl->Perl_he_root
#undef  hexdigit
#define hexdigit		pPerl->Perl_hexdigit
#undef  hintgv
#define hintgv			pPerl->Perl_hintgv
#undef  hints
#define hints			pPerl->Perl_hints
#undef  hv_fetch_ent_mh
#define hv_fetch_ent_mh     pPerl->hv_fetch_ent_mh
#undef  hv_fetch_sv
#define hv_fetch_sv         pPerl->hv_fetch_sv
#undef  in_clean_all
#define in_clean_all		pPerl->Perl_in_clean_all
#undef  in_clean_objs
#define in_clean_objs		pPerl->Perl_in_clean_objs
#undef  in_eval
#define in_eval			pPerl->Perl_in_eval
#undef  in_my
#define in_my			pPerl->Perl_in_my
#undef  in_my_stash
#define in_my_stash		pPerl->Perl_in_my_stash
#undef  incgv
#define incgv			pPerl->Perl_incgv
#undef  initav
#define initav			pPerl->Perl_initav
#undef  inplace
#define inplace			pPerl->Perl_inplace
#undef  last_in_gv
#define last_in_gv		pPerl->Perl_last_in_gv
#undef  last_proto
#define last_proto		pPerl->Perl_last_proto
#undef  last_lop
#define last_lop		pPerl->Perl_last_lop
#undef  last_lop_op
#define last_lop_op		pPerl->Perl_last_lop_op
#undef  last_uni
#define last_uni		pPerl->Perl_last_uni
#undef  lastfd
#define lastfd			pPerl->Perl_lastfd
#undef  lastgotoprobe
#define lastgotoprobe		pPerl->Perl_lastgotoprobe
#undef  lastscream
#define lastscream		pPerl->Perl_lastscream
#undef  lastsize
#define lastsize		pPerl->Perl_lastsize
#undef  lastspbase
#define lastspbase		pPerl->Perl_lastspbase
#undef  laststatval
#define laststatval		pPerl->Perl_laststatval
#undef  laststype
#define laststype		pPerl->Perl_laststype
#undef  leftgv
#define leftgv			pPerl->Perl_leftgv
#undef  lex_brackets
#define lex_brackets		pPerl->Perl_lex_brackets
#undef  lex_brackstack
#define lex_brackstack		pPerl->Perl_lex_brackstack
#undef  lex_casemods
#define lex_casemods		pPerl->Perl_lex_casemods
#undef  lex_casestack
#define lex_casestack		pPerl->Perl_lex_casestack
#undef  lex_defer
#define lex_defer		pPerl->Perl_lex_defer
#undef  lex_dojoin
#define lex_dojoin		pPerl->Perl_lex_dojoin
#undef  lex_expect
#define lex_expect		pPerl->Perl_lex_expect
#undef  lex_fakebrack
#define lex_fakebrack		pPerl->Perl_lex_fakebrack
#undef  lex_formbrack
#define lex_formbrack		pPerl->Perl_lex_formbrack
#undef  lex_inpat
#define lex_inpat		pPerl->Perl_lex_inpat
#undef  lex_inwhat
#define lex_inwhat		pPerl->Perl_lex_inwhat
#undef  lex_op
#define lex_op			pPerl->Perl_lex_op
#undef  lex_repl
#define lex_repl		pPerl->Perl_lex_repl
#undef  lex_starts
#define lex_starts		pPerl->Perl_lex_starts
#undef  lex_state
#define lex_state		pPerl->Perl_lex_state
#undef  lex_stuff
#define lex_stuff		pPerl->Perl_lex_stuff
#undef  lineary
#define lineary			pPerl->Perl_lineary
#undef  linestart
#define linestart		pPerl->Perl_linestart
#undef  linestr
#define linestr			pPerl->Perl_linestr
#undef  localizing
#define localizing		pPerl->Perl_localizing
#undef  localpatches
#define localpatches		pPerl->Perl_localpatches
#undef  main_cv
#define main_cv			pPerl->Perl_main_cv
#undef  main_root
#define main_root		pPerl->Perl_main_root
#undef  main_start
#define main_start		pPerl->Perl_main_start
#undef  mainstack
#define mainstack		pPerl->Perl_mainstack
#undef  malloc_mutex
#define malloc_mutex		pPerl->Perl_malloc_mutex
#undef  markstack
#define markstack		pPerl->Perl_markstack
#undef  markstack_max
#define markstack_max		pPerl->Perl_markstack_max
#undef  markstack_ptr
#define markstack_ptr		pPerl->Perl_markstack_ptr
#undef  max_intro_pending
#define max_intro_pending	pPerl->Perl_max_intro_pending
#undef  maxo
#define maxo			pPerl->Perl_maxo
#undef  maxscream
#define maxscream		pPerl->Perl_maxscream
#undef  maxsysfd
#define maxsysfd		pPerl->Perl_maxsysfd
#undef  mess_sv
#define mess_sv			pPerl->Perl_mess_sv
#undef  min_intro_pending
#define min_intro_pending	pPerl->Perl_min_intro_pending
#undef  minus_F
#define minus_F			pPerl->Perl_minus_F
#undef  minus_a
#define minus_a			pPerl->Perl_minus_a
#undef  minus_c
#define minus_c			pPerl->Perl_minus_c
#undef  minus_l
#define minus_l			pPerl->Perl_minus_l
#undef  minus_n
#define minus_n			pPerl->Perl_minus_n
#undef  minus_p
#define minus_p			pPerl->Perl_minus_p
#undef  modcount
#define modcount		pPerl->Perl_modcount
#undef  modglobal
#define modglobal       pPerl->Perl_modglobal
#undef  multi_close
#define multi_close		pPerl->Perl_multi_close
#undef  multi_end
#define multi_end		pPerl->Perl_multi_end
#undef  multi_open
#define multi_open		pPerl->Perl_multi_open
#undef  multi_start
#define multi_start		pPerl->Perl_multi_start
#undef  multiline
#define multiline		pPerl->Perl_multiline
#undef  mystrk
#define mystrk			pPerl->Perl_mystrk
#undef  na
#define na			pPerl->Perl_na
#undef  nexttoke
#define nexttoke		pPerl->Perl_nexttoke
#undef  nexttype
#define nexttype		pPerl->Perl_nexttype
#undef  nextval
#define nextval			pPerl->Perl_nextval
#undef  nice_chunk
#define nice_chunk		pPerl->Perl_nice_chunk
#undef  nice_chunk_size
#define nice_chunk_size		pPerl->Perl_nice_chunk_size
#undef  nomemok
#define nomemok			pPerl->Perl_nomemok
#undef  nrs
#define nrs			pPerl->Perl_nrs
#undef  nthreads
#define nthreads		pPerl->Perl_nthreads
#undef  nthreads_cond
#define nthreads_cond		pPerl->Perl_nthreads_cond
#undef  numeric_local
#define numeric_local		pPerl->Perl_numeric_local
#undef  numeric_name
#define numeric_name		pPerl->Perl_numeric_name
#undef  numeric_standard
#define numeric_standard	pPerl->Perl_numeric_standard
#undef  ofmt
#define ofmt			pPerl->Perl_ofmt
#undef  ofs
#define ofs			pPerl->Perl_ofs
#undef  ofslen
#define ofslen			pPerl->Perl_ofslen
#undef  oldbufptr
#define oldbufptr		pPerl->Perl_oldbufptr
#undef  oldlastpm
#define oldlastpm		pPerl->Perl_oldlastpm
#undef  oldname
#define oldname			pPerl->Perl_oldname
#undef  oldoldbufptr
#define oldoldbufptr		pPerl->Perl_oldoldbufptr
#undef  op
#define op			pPerl->Perl_op
#undef  op_mask
#define op_mask			pPerl->Perl_op_mask
#undef  op_seqmax
#define op_seqmax		pPerl->Perl_op_seqmax
#undef  opsave
#define opsave			pPerl->Perl_opsave
#undef  origalen
#define origalen		pPerl->Perl_origalen
#undef  origargc
#define origargc		pPerl->Perl_origargc
#undef  origargv
#define origargv		pPerl->Perl_origargv
#undef  origenviron
#define origenviron		pPerl->Perl_origenviron
#undef  origfilename
#define origfilename		pPerl->Perl_origfilename
#undef  ors
#define ors			pPerl->Perl_ors
#undef  orslen
#define orslen			pPerl->Perl_orslen
#undef  osname
#define osname			pPerl->Perl_osname
#undef  pad_reset_pending
#define pad_reset_pending	pPerl->Perl_pad_reset_pending
#undef  padix
#define padix			pPerl->Perl_padix
#undef  padix_floor
#define padix_floor		pPerl->Perl_padix_floor
#undef  parsehook
#define parsehook		pPerl->Perl_parsehook
#undef  patchlevel
#define patchlevel		pPerl->Perl_patchlevel
#undef  patleave
#define patleave		pPerl->Perl_patleave
#undef  pending_ident
#define pending_ident		pPerl->Perl_pending_ident
#undef  perl_destruct_level
#define perl_destruct_level	pPerl->Perl_perl_destruct_level
#undef  perldb
#define perldb			pPerl->Perl_perldb
#undef  pidstatus
#define pidstatus		pPerl->Perl_pidstatus
#undef  preambleav
#define preambleav		pPerl->Perl_preambleav
#undef  preambled
#define preambled		pPerl->Perl_preambled
#undef  preprocess
#define preprocess		pPerl->Perl_preprocess
#undef  profiledata
#define profiledata		pPerl->Perl_profiledata
#undef  reg_eval_set
#define reg_eval_set		pPerl->Perl_reg_eval_set
#undef  reg_flags
#define reg_flags		pPerl->Perl_reg_flags
#undef  reg_start_tmp
#define reg_start_tmp		pPerl->Perl_reg_start_tmp
#undef  reg_start_tmpl
#define reg_start_tmpl		pPerl->Perl_reg_start_tmpl
#undef  regbol
#define regbol			pPerl->Perl_regbol
#undef  regcc
#define regcc			pPerl->Perl_regcc
#undef  regcode
#define regcode			pPerl->Perl_regcode
#undef  regdata
#define regdata			pPerl->Perl_regdata
#undef  regdummy
#define regdummy		pPerl->Perl_regdummy
#undef  regendp
#define regendp			pPerl->Perl_regendp
#undef  regeol
#define regeol			pPerl->Perl_regeol
#undef  regflags
#define regflags		pPerl->Perl_regflags
#undef  regindent
#define regindent		pPerl->Perl_regindent
#undef  reginput
#define reginput		pPerl->Perl_reginput
#undef  reginterp_cnt
#define reginterp_cnt		pPerl->Perl_reginterp_cnt
#undef  reglastparen
#define reglastparen		pPerl->Perl_reglastparen
#undef  regnarrate
#define regnarrate		pPerl->Perl_regnarrate
#undef  regnaughty
#define regnaughty		pPerl->Perl_regnaughty
#undef  regnpar
#define regnpar			pPerl->Perl_regnpar
#undef  regcomp_parse
#define regcomp_parse		pPerl->Perl_regcomp_parse
#undef  regprecomp
#define regprecomp		pPerl->Perl_regprecomp
#undef  regprev
#define regprev			pPerl->Perl_regprev
#undef  regprogram
#define regprogram		pPerl->Perl_regprogram
#undef  regsawback
#define regsawback		pPerl->Perl_regsawback
#undef  regseen
#define regseen			pPerl->Perl_regseen
#undef  regsize
#define regsize			pPerl->Perl_regsize
#undef  regstartp
#define regstartp		pPerl->Perl_regstartp
#undef  regtill
#define regtill			pPerl->Perl_regtill
#undef  regxend
#define regxend			pPerl->Perl_regxend
#undef  restartop
#define restartop		pPerl->Perl_restartop
#undef  retstack
#define retstack		pPerl->Perl_retstack
#undef  retstack_ix
#define retstack_ix		pPerl->Perl_retstack_ix
#undef  retstack_max
#define retstack_max		pPerl->Perl_retstack_max
#undef  rightgv
#define rightgv			pPerl->Perl_rightgv
#undef  rs
#define rs			pPerl->Perl_rs
#undef  rsfp
#define rsfp			pPerl->Perl_rsfp
#undef  rsfp_filters
#define rsfp_filters		pPerl->Perl_rsfp_filters
#undef  runops
#define runops			pPerl->Perl_runops
#undef  regcomp_rx
#define regcomp_rx		pPerl->Perl_regcomp_rx
#undef  savestack
#define savestack		pPerl->Perl_savestack
#undef  savestack_ix
#define savestack_ix		pPerl->Perl_savestack_ix
#undef  savestack_max
#define savestack_max		pPerl->Perl_savestack_max
#undef  sawampersand
#define sawampersand		pPerl->Perl_sawampersand
#undef  sawstudy
#define sawstudy		pPerl->Perl_sawstudy
#undef  sawvec
#define sawvec			pPerl->Perl_sawvec
#undef  scopestack
#define scopestack		pPerl->Perl_scopestack
#undef  scopestack_ix
#define scopestack_ix		pPerl->Perl_scopestack_ix
#undef  scopestack_max
#define scopestack_max		pPerl->Perl_scopestack_max
#undef  screamfirst
#define screamfirst		pPerl->Perl_screamfirst
#undef  screamnext
#define screamnext		pPerl->Perl_screamnext
#undef  secondgv
#define secondgv		pPerl->Perl_secondgv
#undef  seen_zerolen
#define seen_zerolen		pPerl->Perl_seen_zerolen
#undef  seen_evals
#define seen_evals		pPerl->Perl_seen_evals
#undef  sh_path
#define sh_path			pPerl->Perl_sh_path
#undef  siggv
#define siggv			pPerl->Perl_siggv
#undef  sighandlerp
#define sighandlerp		pPerl->Perl_sighandlerp
#undef  sortcop
#define sortcop			pPerl->Perl_sortcop
#undef  sortcxix
#define sortcxix		pPerl->Perl_sortcxix
#undef  sortstash
#define sortstash		pPerl->Perl_sortstash
#undef  specialsv_list
#define specialsv_list  pPerl->Perl_specialsv_list
#undef  splitstr
#define splitstr		pPerl->Perl_splitstr
#undef  stack_base
#define stack_base		pPerl->Perl_stack_base
#undef  stack_max
#define stack_max		pPerl->Perl_stack_max
#undef  stack_sp
#define stack_sp		pPerl->Perl_stack_sp
#undef  start_env
#define start_env		pPerl->Perl_start_env
#undef  statbuf
#define statbuf			pPerl->Perl_statbuf
#undef  statcache
#define statcache		pPerl->Perl_statcache
#undef  statgv
#define statgv			pPerl->Perl_statgv
#undef  statname
#define statname		pPerl->Perl_statname
#undef  statusvalue
#define statusvalue		pPerl->Perl_statusvalue
#undef  statusvalue_vms
#define statusvalue_vms		pPerl->Perl_statusvalue_vms
#undef  stdingv
#define stdingv			pPerl->Perl_stdingv
#undef  strchop
#define strchop			pPerl->Perl_strchop
#undef  strtab
#define strtab			pPerl->Perl_strtab
#undef  sub_generation
#define sub_generation		pPerl->Perl_sub_generation
#undef  sublex_info
#define sublex_info		pPerl->Perl_sublex_info
#undef  subline
#define subline			pPerl->Perl_subline
#undef  subname
#define subname			pPerl->Perl_subname
#undef  sv_arenaroot
#define sv_arenaroot		pPerl->Perl_sv_arenaroot
#undef  sv_count
#define sv_count		pPerl->Perl_sv_count
#undef  sv_mutex
#define sv_mutex		pPerl->Perl_sv_mutex
#undef  sv_no
#define sv_no			pPerl->Perl_sv_no
#undef  sv_objcount
#define sv_objcount		pPerl->Perl_sv_objcount
#undef  sv_root
#define sv_root			pPerl->Perl_sv_root
#undef  sv_undef
#define sv_undef		pPerl->Perl_sv_undef
#undef  sv_yes
#define sv_yes			pPerl->Perl_sv_yes
#undef  svref_mutex
#define svref_mutex         pPerl->svref_mutex
#undef  sys_intern
#define sys_intern		pPerl->Perl_sys_intern
#undef  tainted
#define tainted			pPerl->Perl_tainted
#undef  tainting
#define tainting		pPerl->Perl_tainting
#undef  thisexpr
#define thisexpr		pPerl->Perl_thisexpr
#undef  thr_key
#define thr_key			pPerl->Perl_thr_key
#undef  threadnum
#define threadnum		pPerl->Perl_threadnum
#undef  threads_mutex
#define threads_mutex		pPerl->Perl_threads_mutex
#undef  threadsv_names
#define threadsv_names		pPerl->Perl_threadsv_names
#undef  thrsv
#define thrsv			pPerl->Perl_thrsv
#undef  timesbuf
#define timesbuf		pPerl->Perl_timesbuf
#undef  tmps_floor
#define tmps_floor		pPerl->Perl_tmps_floor
#undef  tmps_ix
#define tmps_ix			pPerl->Perl_tmps_ix
#undef  tmps_max
#define tmps_max		pPerl->Perl_tmps_max
#undef  tmps_stack
#define tmps_stack		pPerl->Perl_tmps_stack
#undef  tokenbuf
#define tokenbuf		pPerl->Perl_tokenbuf
#undef  top_env
#define top_env			pPerl->Perl_top_env
#undef  toptarget
#define toptarget		pPerl->Perl_toptarget
#undef  uid
#define uid			pPerl->Perl_uid
#undef  unsafe
#define unsafe			pPerl->Perl_unsafe
#undef  warnhook
#define warnhook		pPerl->Perl_warnhook
#undef  xiv_arenaroot
#define xiv_arenaroot		pPerl->Perl_xiv_arenaroot
#undef  xiv_root
#define xiv_root		pPerl->Perl_xiv_root
#undef  xnv_root
#define xnv_root		pPerl->Perl_xnv_root
#undef  xpv_root
#define xpv_root		pPerl->Perl_xpv_root
#undef  xrv_root
#define xrv_root		pPerl->Perl_xrv_root

/* Functions */

#undef  amagic_call
#define amagic_call         pPerl->Perl_amagic_call
#undef  Perl_GetVars
#define Perl_GetVars        pPerl->Perl_GetVars
#undef  Gv_AMupdate
#define Gv_AMupdate         pPerl->Perl_Gv_AMupdate
#undef  append_elem
#define append_elem         pPerl->Perl_append_elem
#undef  append_list
#define append_list         pPerl->Perl_append_list
#undef  apply
#define apply               pPerl->Perl_apply
#undef  assertref
#define assertref           pPerl->Perl_assertref
#undef  av_clear
#define av_clear            pPerl->Perl_av_clear
#undef  av_extend
#define av_extend           pPerl->Perl_av_extend
#undef  av_fake
#define av_fake             pPerl->Perl_av_fake
#undef  av_fetch
#define av_fetch            pPerl->Perl_av_fetch
#undef  av_fill
#define av_fill             pPerl->Perl_av_fill
#undef  av_len
#define av_len              pPerl->Perl_av_len
#undef  av_make
#define av_make             pPerl->Perl_av_make
#undef  av_pop
#define av_pop              pPerl->Perl_av_pop
#undef  av_push
#define av_push             pPerl->Perl_av_push
#undef  av_reify
#define av_reify            pPerl->Perl_av_reify
#undef  av_shift
#define av_shift            pPerl->Perl_av_shift
#undef  av_store
#define av_store            pPerl->Perl_av_store
#undef  av_undef
#define av_undef            pPerl->Perl_av_undef
#undef  av_unshift
#define av_unshift          pPerl->Perl_av_unshift
#undef  avhv_exists_ent
#define avhv_exists_ent     pPerl->Perl_avhv_exists_ent
#undef  avhv_fetch_ent
#define avhv_fetch_ent      pPerl->Perl_avhv_fetch_ent
#undef  avhv_iternext
#define avhv_iternext       pPerl->Perl_avhv_iternext
#undef  avhv_iterval
#define avhv_iterval        pPerl->Perl_avhv_iterval
#undef  avhv_keys
#define avhv_keys           pPerl->Perl_avhv_keys
#undef  bind_match
#define bind_match          pPerl->Perl_bind_match
#undef  block_end
#define block_end           pPerl->Perl_block_end
#undef  block_gimme
#define block_gimme         pPerl->Perl_block_gimme
#undef  block_start
#define block_start         pPerl->Perl_block_start
#undef  call_list
#define call_list           pPerl->Perl_call_list
#undef  cando
#define cando               pPerl->Perl_cando
#undef  cast_ulong
#define cast_ulong          pPerl->Perl_cast_ulong
#undef  checkcomma
#define checkcomma          pPerl->Perl_checkcomma
#undef  check_uni
#define check_uni           pPerl->Perl_check_uni
#undef  ck_concat
#define ck_concat           pPerl->Perl_ck_concat
#undef  ck_delete
#define ck_delete           pPerl->Perl_ck_delete
#undef  ck_eof
#define ck_eof              pPerl->Perl_ck_eof
#undef  ck_eval
#define ck_eval             pPerl->Perl_ck_eval
#undef  ck_exec
#define ck_exec             pPerl->Perl_ck_exec
#undef  ck_formline
#define ck_formline         pPerl->Perl_ck_formline
#undef  ck_ftst
#define ck_ftst             pPerl->Perl_ck_ftst
#undef  ck_fun
#define ck_fun              pPerl->Perl_ck_fun
#undef  ck_glob
#define ck_glob             pPerl->Perl_ck_glob
#undef  ck_grep
#define ck_grep             pPerl->Perl_ck_grep
#undef  ck_gvconst
#define ck_gvconst          pPerl->Perl_ck_gvconst
#undef  ck_index
#define ck_index            pPerl->Perl_ck_index
#undef  ck_lengthconst
#define ck_lengthconst      pPerl->Perl_ck_lengthconst
#undef  ck_lfun
#define ck_lfun             pPerl->Perl_ck_lfun
#undef  ck_listiob
#define ck_listiob          pPerl->Perl_ck_listiob
#undef  ck_match
#define ck_match            pPerl->Perl_ck_match
#undef  ck_null
#define ck_null             pPerl->Perl_ck_null
#undef  ck_repeat
#define ck_repeat           pPerl->Perl_ck_repeat
#undef  ck_require
#define ck_require          pPerl->Perl_ck_require
#undef  ck_retarget
#define ck_retarget         pPerl->Perl_ck_retarget
#undef  ck_rfun
#define ck_rfun             pPerl->Perl_ck_rfun
#undef  ck_rvconst
#define ck_rvconst          pPerl->Perl_ck_rvconst
#undef  ck_select
#define ck_select           pPerl->Perl_ck_select
#undef  ck_shift
#define ck_shift            pPerl->Perl_ck_shift
#undef  ck_sort
#define ck_sort             pPerl->Perl_ck_sort
#undef  ck_spair
#define ck_spair            pPerl->Perl_ck_spair
#undef  ck_split
#define ck_split            pPerl->Perl_ck_split
#undef  ck_subr
#define ck_subr             pPerl->Perl_ck_subr
#undef  ck_svconst
#define ck_svconst          pPerl->Perl_ck_svconst
#undef  ck_trunc
#define ck_trunc            pPerl->Perl_ck_trunc
#undef  condpair_magic
#define condpair_magic      pPerl->Perl_condpair_magic
#undef  convert
#define convert             pPerl->Perl_convert
#undef  cpytill
#define cpytill             pPerl->Perl_cpytill
#undef  croak
#define croak               pPerl->Perl_croak
#undef  cv_ckproto
#define cv_ckproto          pPerl->Perl_cv_ckproto
#undef  cv_clone
#define cv_clone            pPerl->Perl_cv_clone
#undef  cv_const_sv
#define cv_const_sv         pPerl->Perl_cv_const_sv
#undef  cv_undef
#define cv_undef            pPerl->Perl_cv_undef
#undef  cx_dump
#define cx_dump             pPerl->Perl_cx_dump
#undef  cxinc
#define cxinc               pPerl->Perl_cxinc
#undef  deb
#define deb                 pPerl->Perl_deb
#undef  deb_growlevel
#define deb_growlevel       pPerl->Perl_deb_growlevel
#undef  debprofdump
#define debprofdump         pPerl->Perl_debprofdump
#undef  debop
#define debop               pPerl->Perl_debop
#undef  debstack
#define debstack            pPerl->Perl_debstack
#undef  debstackptrs
#define debstackptrs        pPerl->Perl_debstackptrs
#undef  delimcpy
#define delimcpy            pPerl->Perl_delimcpy
#undef  deprecate
#define deprecate           pPerl->Perl_deprecate
#undef  die
#define die                 pPerl->Perl_die
#undef  die_where
#define die_where           pPerl->Perl_die_where
#undef  dopoptoeval
#define dopoptoeval         pPerl->Perl_dopoptoeval
#undef  dounwind
#define dounwind            pPerl->Perl_dounwind
#undef  do_aexec
#define do_aexec            pPerl->Perl_do_aexec
#undef  do_binmode
#define do_binmode          pPerl->Perl_do_binmode
#undef  do_chomp
#define do_chomp            pPerl->Perl_do_chomp
#undef  do_chop
#define do_chop             pPerl->Perl_do_chop
#undef  do_close
#define do_close            pPerl->Perl_do_close
#undef  do_eof
#define do_eof              pPerl->Perl_do_eof
#undef  do_exec
#define do_exec             pPerl->Perl_do_exec
#undef  do_execfree
#define do_execfree         pPerl->Perl_do_execfree
#undef  do_join
#define do_join             pPerl->Perl_do_join
#undef  do_kv
#define do_kv               pPerl->Perl_do_kv
#undef  do_open
#define do_open             pPerl->Perl_do_open
#undef  do_pipe
#define do_pipe             pPerl->Perl_do_pipe
#undef  do_print
#define do_print            pPerl->Perl_do_print
#undef  do_readline
#define do_readline         pPerl->Perl_do_readline
#undef  do_seek
#define do_seek             pPerl->Perl_do_seek
#undef  do_sprintf
#define do_sprintf          pPerl->Perl_do_sprintf
#undef  do_sysseek
#define do_sysseek          pPerl->Perl_do_sysseek
#undef  do_tell
#define do_tell             pPerl->Perl_do_tell
#undef  do_trans
#define do_trans            pPerl->Perl_do_trans
#undef  do_vecset
#define do_vecset           pPerl->Perl_do_vecset
#undef  do_vop
#define do_vop              pPerl->Perl_do_vop
#undef  dowantarray
#define dowantarray         pPerl->Perl_dowantarray
#undef  dump_all
#define dump_all            pPerl->Perl_dump_all
#undef  dump_eval
#define dump_eval           pPerl->Perl_dump_eval
#undef  dump_fds
#define dump_fds            pPerl->Perl_dump_fds
#undef  dump_form
#define dump_form           pPerl->Perl_dump_form
#undef  dump_gv
#define dump_gv             pPerl->Perl_dump_gv
#undef  dump_mstats
#define dump_mstats         pPerl->Perl_dump_mstats
#undef  dump_op
#define dump_op             pPerl->Perl_dump_op
#undef  dump_pm
#define dump_pm             pPerl->Perl_dump_pm
#undef  dump_packsubs
#define dump_packsubs       pPerl->Perl_dump_packsubs
#undef  dump_sub
#define dump_sub            pPerl->Perl_dump_sub
#undef  fbm_compile
#define fbm_compile         pPerl->Perl_fbm_compile
#undef  fbm_instr
#define fbm_instr           pPerl->Perl_fbm_instr
#undef  filter_add
#define filter_add          pPerl->Perl_filter_add
#undef  filter_del
#define filter_del          pPerl->Perl_filter_del
#undef  filter_read
#define filter_read         pPerl->Perl_filter_read
#undef  find_threadsv
#define find_threadsv       pPerl->Perl_find_threadsv
#undef  find_script
#define find_script         pPerl->Perl_find_script
#undef  force_ident
#define force_ident         pPerl->Perl_force_ident
#undef  force_list
#define force_list          pPerl->Perl_force_list
#undef  force_next
#define force_next          pPerl->Perl_force_next
#undef  force_word
#define force_word          pPerl->Perl_force_word
#undef  form
#define form                pPerl->Perl_form
#undef  fold_constants
#define fold_constants      pPerl->Perl_fold_constants
#undef  fprintf
#define fprintf             pPerl->fprintf
#undef  free_tmps
#define free_tmps           pPerl->Perl_free_tmps
#undef  gen_constant_list
#define gen_constant_list   pPerl->Perl_gen_constant_list
#undef  get_op_descs
#define get_op_descs        pPerl->Perl_get_op_descs
#undef  get_op_names
#define get_op_names        pPerl->Perl_get_op_names
#undef  get_no_modify
#define get_no_modify       pPerl->Perl_get_no_modify
#undef  get_opargs
#define get_opargs	        pPerl->Perl_get_opargs
#undef  get_specialsv_list
#define get_specialsv_list  pPerl->Perl_get_specialsv_list
#undef  gp_free
#define gp_free             pPerl->Perl_gp_free
#undef  gp_ref
#define gp_ref              pPerl->Perl_gp_ref
#undef  gv_AVadd
#define gv_AVadd            pPerl->Perl_gv_AVadd
#undef  gv_HVadd
#define gv_HVadd            pPerl->Perl_gv_HVadd
#undef  gv_IOadd
#define gv_IOadd            pPerl->Perl_gv_IOadd
#undef  gv_autoload4
#define gv_autoload4        pPerl->Perl_gv_autoload4
#undef  gv_check
#define gv_check            pPerl->Perl_gv_check
#undef  gv_efullname
#define gv_efullname        pPerl->Perl_gv_efullname
#undef  gv_efullname3
#define gv_efullname3       pPerl->Perl_gv_efullname3
#undef  gv_fetchfile
#define gv_fetchfile        pPerl->Perl_gv_fetchfile
#undef  gv_fetchmeth
#define gv_fetchmeth        pPerl->Perl_gv_fetchmeth
#undef  gv_fetchmethod
#define gv_fetchmethod      pPerl->Perl_gv_fetchmethod
#undef  gv_fetchmethod_autoload
#define gv_fetchmethod_autoload pPerl->Perl_gv_fetchmethod_autoload
#undef  gv_fetchpv
#define gv_fetchpv          pPerl->Perl_gv_fetchpv
#undef  gv_fullname
#define gv_fullname         pPerl->Perl_gv_fullname
#undef  gv_fullname3
#define gv_fullname3        pPerl->Perl_gv_fullname3
#undef  gv_init
#define gv_init             pPerl->Perl_gv_init
#undef  gv_stashpv
#define gv_stashpv          pPerl->Perl_gv_stashpv
#undef  gv_stashpvn
#define gv_stashpvn         pPerl->Perl_gv_stashpvn
#undef  gv_stashsv
#define gv_stashsv          pPerl->Perl_gv_stashsv
#undef  he_delayfree
#define he_delayfree        pPerl->Perl_he_delayfree
#undef  he_free
#define he_free             pPerl->Perl_he_free
#undef  hoistmust
#define hoistmust           pPerl->Perl_hoistmust
#undef  hv_clear
#define hv_clear            pPerl->Perl_hv_clear
#undef  hv_delayfree_ent
#define hv_delayfree_ent    pPerl->Perl_hv_delayfree_ent
#undef  hv_delete
#define hv_delete           pPerl->Perl_hv_delete
#undef  hv_delete_ent
#define hv_delete_ent       pPerl->Perl_hv_delete_ent
#undef  hv_exists
#define hv_exists           pPerl->Perl_hv_exists
#undef  hv_exists_ent
#define hv_exists_ent       pPerl->Perl_hv_exists_ent
#undef  hv_fetch
#define hv_fetch            pPerl->Perl_hv_fetch
#undef  hv_fetch_ent
#define hv_fetch_ent        pPerl->Perl_hv_fetch_ent
#undef  hv_free_ent
#define hv_free_ent         pPerl->Perl_hv_free_ent
#undef  hv_iterinit
#define hv_iterinit         pPerl->Perl_hv_iterinit
#undef  hv_iterkey
#define hv_iterkey          pPerl->Perl_hv_iterkey
#undef  hv_iterkeysv
#define hv_iterkeysv        pPerl->Perl_hv_iterkeysv
#undef  hv_iternext
#define hv_iternext         pPerl->Perl_hv_iternext
#undef  hv_iternextsv
#define hv_iternextsv       pPerl->Perl_hv_iternextsv
#undef  hv_iterval
#define hv_iterval          pPerl->Perl_hv_iterval
#undef  hv_ksplit
#define hv_ksplit           pPerl->Perl_hv_ksplit
#undef  hv_magic
#define hv_magic            pPerl->Perl_hv_magic
#undef  hv_store
#define hv_store            pPerl->Perl_hv_store
#undef  hv_store_ent
#define hv_store_ent        pPerl->Perl_hv_store_ent
#undef  hv_undef
#define hv_undef            pPerl->Perl_hv_undef
#undef  ibcmp
#define ibcmp               pPerl->Perl_ibcmp
#undef  ibcmp_locale
#define ibcmp_locale        pPerl->Perl_ibcmp_locale
#undef  incpush
#define incpush             pPerl->incpush
#undef  incline
#define incline             pPerl->incline
#undef  incl_perldb
#define incl_perldb         pPerl->incl_perldb
#undef  ingroup
#define ingroup             pPerl->Perl_ingroup
#undef  init_stacks
#define init_stacks         pPerl->Perl_init_stacks
#undef  instr
#define instr               pPerl->Perl_instr
#undef  intro_my
#define intro_my            pPerl->Perl_intro_my
#undef  intuit_method
#define intuit_method       pPerl->intuit_method
#undef  intuit_more
#define intuit_more         pPerl->Perl_intuit_more
#undef  invert
#define invert              pPerl->Perl_invert
#undef  io_close
#define io_close            pPerl->Perl_io_close
#undef  ioctl
#define ioctl               pPerl->ioctl
#undef  jmaybe
#define jmaybe              pPerl->Perl_jmaybe
#undef  keyword
#define keyword             pPerl->Perl_keyword
#undef  leave_scope
#define leave_scope         pPerl->Perl_leave_scope
#undef  lex_end
#define lex_end             pPerl->Perl_lex_end
#undef  lex_start
#define lex_start           pPerl->Perl_lex_start
#undef  linklist
#define linklist            pPerl->Perl_linklist
#undef  list
#define list                pPerl->Perl_list
#undef  listkids
#define listkids            pPerl->Perl_listkids
#undef  lop
#define lop                 pPerl->lop
#undef  localize
#define localize            pPerl->Perl_localize
#undef  looks_like_number
#define looks_like_number   pPerl->Perl_looks_like_number
#undef  magic_clear_all_env
#define magic_clear_all_env pPerl->Perl_magic_clear_all_env
#undef  magic_clearenv
#define magic_clearenv      pPerl->Perl_magic_clearenv
#undef  magic_clearpack
#define magic_clearpack     pPerl->Perl_magic_clearpack
#undef  magic_clearsig
#define magic_clearsig      pPerl->Perl_magic_clearsig
#undef  magic_existspack
#define magic_existspack    pPerl->Perl_magic_existspack
#undef  magic_freeregexp
#define magic_freeregexp    pPerl->Perl_magic_freeregexp
#undef  magic_get
#define magic_get           pPerl->Perl_magic_get
#undef  magic_getarylen
#define magic_getarylen     pPerl->Perl_magic_getarylen
#undef  magic_getdefelem
#define magic_getdefelem    pPerl->Perl_magic_getdefelem
#undef  magic_getpack
#define magic_getpack       pPerl->Perl_magic_getpack
#undef  magic_getglob
#define magic_getglob       pPerl->Perl_magic_getglob
#undef  magic_getnkeys
#define magic_getnkeys      pPerl->Perl_magic_getnkeys
#undef  magic_getpos
#define magic_getpos        pPerl->Perl_magic_getpos
#undef  magic_getsig
#define magic_getsig        pPerl->Perl_magic_getsig
#undef  magic_getsubstr
#define magic_getsubstr     pPerl->Perl_magic_getsubstr
#undef  magic_gettaint
#define magic_gettaint      pPerl->Perl_magic_gettaint
#undef  magic_getuvar
#define magic_getuvar       pPerl->Perl_magic_getuvar
#undef  magic_getvec
#define magic_getvec        pPerl->Perl_magic_getvec
#undef  magic_len
#define magic_len           pPerl->Perl_magic_len
#undef  magic_methpack
#define magic_methpack      pPerl->magic_methpack
#undef  magic_mutexfree
#define magic_mutexfree     pPerl->Perl_magic_mutexfree
#undef  magic_nextpack
#define magic_nextpack      pPerl->Perl_magic_nextpack
#undef  magic_set
#define magic_set           pPerl->Perl_magic_set
#undef  magic_set_all_env
#define magic_set_all_env   pPerl->Perl_magic_set_all_env
#undef  magic_setamagic
#define magic_setamagic     pPerl->Perl_magic_setamagic
#undef  magic_setarylen
#define magic_setarylen     pPerl->Perl_magic_setarylen
#undef  magic_setbm
#define magic_setbm         pPerl->Perl_magic_setbm
#undef  magic_setcollxfrm
#define magic_setcollxfrm   pPerl->Perl_magic_setcollxfrm
#undef  magic_setdbline
#define magic_setdbline     pPerl->Perl_magic_setdbline
#undef  magic_setdefelem
#define magic_setdefelem    pPerl->Perl_magic_setdefelem
#undef  magic_setenv
#define magic_setenv        pPerl->Perl_magic_setenv
#undef  magic_setfm
#define magic_setfm         pPerl->Perl_magic_setfm
#undef  magic_setisa
#define magic_setisa        pPerl->Perl_magic_setisa
#undef  magic_setglob
#define magic_setglob       pPerl->Perl_magic_setglob
#undef  magic_setmglob
#define magic_setmglob      pPerl->Perl_magic_setmglob
#undef  magic_setnkeys
#define magic_setnkeys      pPerl->Perl_magic_setnkeys
#undef  magic_setpack
#define magic_setpack       pPerl->Perl_magic_setpack
#undef  magic_setpos
#define magic_setpos        pPerl->Perl_magic_setpos
#undef  magic_setsig
#define magic_setsig        pPerl->Perl_magic_setsig
#undef  magic_setsubstr
#define magic_setsubstr     pPerl->Perl_magic_setsubstr
#undef  magic_settaint
#define magic_settaint      pPerl->Perl_magic_settaint
#undef  magic_setuvar
#define magic_setuvar       pPerl->Perl_magic_setuvar
#undef  magic_setvec
#define magic_setvec        pPerl->Perl_magic_setvec
#undef  magic_sizepack
#define magic_sizepack      pPerl->Perl_magic_sizepack
#undef  magic_unchain
#define magic_unchain       pPerl->Perl_magic_unchain
#undef  magic_wipepack
#define magic_wipepack      pPerl->Perl_magic_wipepack
#undef  magicname
#define magicname           pPerl->Perl_magicname
#undef  malloced_size
#define malloced_size       pPerl->Perl_malloced_size
#undef  markstack_grow
#define markstack_grow      pPerl->Perl_markstack_grow
#undef  mem_collxfrm
#define mem_collxfrm        pPerl->Perl_mem_collxfrm
#undef  mess
#define mess                pPerl->Perl_mess
#undef  mg_clear
#define mg_clear            pPerl->Perl_mg_clear
#undef  mg_copy
#define mg_copy             pPerl->Perl_mg_copy
#undef  mg_find
#define mg_find             pPerl->Perl_mg_find
#undef  mg_free
#define mg_free             pPerl->Perl_mg_free
#undef  mg_get
#define mg_get              pPerl->Perl_mg_get
#undef  mg_magical
#define mg_magical          pPerl->Perl_mg_magical
#undef  mg_length
#define mg_length           pPerl->Perl_mg_length
#undef  mg_set
#define mg_set              pPerl->Perl_mg_set
#undef  mg_size
#define mg_size             pPerl->Perl_mg_size
#undef  missingterm
#define missingterm         pPerl->missingterm
#undef  mod
#define mod                 pPerl->Perl_mod
#undef  modkids
#define modkids             pPerl->Perl_modkids
#undef  moreswitches
#define moreswitches        pPerl->Perl_moreswitches
#undef  more_sv
#define more_sv             pPerl->more_sv
#undef  more_xiv
#define more_xiv            pPerl->more_xiv
#undef  more_xnv
#define more_xnv            pPerl->more_xnv
#undef  more_xpv
#define more_xpv            pPerl->more_xpv
#undef  more_xrv
#define more_xrv            pPerl->more_xrv
#undef  my
#define my                  pPerl->Perl_my
#undef  my_bcopy
#define my_bcopy            pPerl->Perl_my_bcopy
#undef  my_bzero
#define my_bzero            pPerl->Perl_my_bzero
#undef  my_chsize
#define my_chsize           pPerl->Perl_my_chsize
#undef  my_exit
#define my_exit             pPerl->Perl_my_exit
#undef  my_failure_exit
#define my_failure_exit     pPerl->Perl_my_failure_exit
#undef  my_htonl
#define my_htonl            pPerl->Perl_my_htonl
#undef  my_lstat
#define my_lstat            pPerl->Perl_my_lstat
#undef  my_memcmp
#define my_memcmp           pPerl->my_memcmp
#undef  my_ntohl
#define my_ntohl            pPerl->Perl_my_ntohl
#undef  my_pclose
#define my_pclose           pPerl->Perl_my_pclose
#undef  my_popen
#define my_popen            pPerl->Perl_my_popen
#undef  my_setenv
#define my_setenv           pPerl->Perl_my_setenv
#undef  my_stat
#define my_stat             pPerl->Perl_my_stat
#undef  my_swap
#define my_swap             pPerl->Perl_my_swap
#undef  my_unexec
#define my_unexec           pPerl->Perl_my_unexec
#undef  newANONLIST
#define newANONLIST         pPerl->Perl_newANONLIST
#undef  newANONHASH
#define newANONHASH         pPerl->Perl_newANONHASH
#undef  newANONSUB
#define newANONSUB          pPerl->Perl_newANONSUB
#undef  newASSIGNOP
#define newASSIGNOP         pPerl->Perl_newASSIGNOP
#undef  newCONDOP
#define newCONDOP           pPerl->Perl_newCONDOP
#undef  newCONSTSUB
#define newCONSTSUB         pPerl->Perl_newCONSTSUB
#undef  newFORM
#define newFORM             pPerl->Perl_newFORM
#undef  newFOROP
#define newFOROP            pPerl->Perl_newFOROP
#undef  newLOGOP
#define newLOGOP            pPerl->Perl_newLOGOP
#undef  newLOOPEX
#define newLOOPEX           pPerl->Perl_newLOOPEX
#undef  newLOOPOP
#define newLOOPOP           pPerl->Perl_newLOOPOP
#undef  newMETHOD
#define newMETHOD           pPerl->Perl_newMETHOD
#undef  newNULLLIST
#define newNULLLIST         pPerl->Perl_newNULLLIST
#undef  newOP
#define newOP               pPerl->Perl_newOP
#undef  newPROG
#define newPROG             pPerl->Perl_newPROG
#undef  newRANGE
#define newRANGE            pPerl->Perl_newRANGE
#undef  newSLICEOP
#define newSLICEOP          pPerl->Perl_newSLICEOP
#undef  newSTATEOP
#define newSTATEOP          pPerl->Perl_newSTATEOP
#undef  newSUB
#define newSUB              pPerl->Perl_newSUB
#undef  newXS
#define newXS               pPerl->Perl_newXS
#undef  newAV
#define newAV               pPerl->Perl_newAV
#undef  newAVREF
#define newAVREF            pPerl->Perl_newAVREF
#undef  newBINOP
#define newBINOP            pPerl->Perl_newBINOP
#undef  newCVREF
#define newCVREF            pPerl->Perl_newCVREF
#undef  newCVOP
#define newCVOP             pPerl->Perl_newCVOP
#undef  newGVOP
#define newGVOP             pPerl->Perl_newGVOP
#undef  newGVgen
#define newGVgen            pPerl->Perl_newGVgen
#undef  newGVREF
#define newGVREF            pPerl->Perl_newGVREF
#undef  newHVREF
#define newHVREF            pPerl->Perl_newHVREF
#undef  newHV
#define newHV               pPerl->Perl_newHV
#undef  newHVhv
#define newHVhv             pPerl->Perl_newHVhv
#undef  newIO
#define newIO               pPerl->Perl_newIO
#undef  newLISTOP
#define newLISTOP           pPerl->Perl_newLISTOP
#undef  newPMOP
#define newPMOP             pPerl->Perl_newPMOP
#undef  newPVOP
#define newPVOP             pPerl->Perl_newPVOP
#undef  newRV
#define newRV               pPerl->Perl_newRV
#undef  newRV_noinc
#undef  Perl_newRV_noinc
#define newRV_noinc         pPerl->Perl_newRV_noinc
#undef  newSV
#define newSV               pPerl->Perl_newSV
#undef  newSVREF
#define newSVREF            pPerl->Perl_newSVREF
#undef  newSVOP
#define newSVOP             pPerl->Perl_newSVOP
#undef  newSViv
#define newSViv             pPerl->Perl_newSViv
#undef  newSVnv
#define newSVnv             pPerl->Perl_newSVnv
#undef  newSVpv
#define newSVpv             pPerl->Perl_newSVpv
#undef  newSVpvf
#define newSVpvf            pPerl->Perl_newSVpvf
#undef  newSVpvn
#define newSVpvn            pPerl->Perl_newSVpvn
#undef  newSVrv
#define newSVrv             pPerl->Perl_newSVrv
#undef  newSVsv
#define newSVsv             pPerl->Perl_newSVsv
#undef  newUNOP
#define newUNOP             pPerl->Perl_newUNOP
#undef  newWHILEOP
#define newWHILEOP          pPerl->Perl_newWHILEOP
#undef  new_struct_thread
#define new_struct_thread   pPerl->Perl_new_struct_thread
#undef  new_stackinfo
#define new_stackinfo       pPerl->Perl_new_stackinfo
#undef  new_sv
#define new_sv              pPerl->new_sv
#undef  new_xnv
#define new_xnv             pPerl->new_xnv
#undef  new_xpv
#define new_xpv             pPerl->new_xpv
#undef  nextargv
#define nextargv            pPerl->Perl_nextargv
#undef  nextchar
#define nextchar            pPerl->nextchar
#undef  ninstr
#define ninstr              pPerl->Perl_ninstr
#undef  no_fh_allowed
#define no_fh_allowed       pPerl->Perl_no_fh_allowed
#undef  no_op
#define no_op               pPerl->Perl_no_op
#undef  package
#define package             pPerl->Perl_package
#undef  pad_alloc
#define pad_alloc           pPerl->Perl_pad_alloc
#undef  pad_allocmy
#define pad_allocmy         pPerl->Perl_pad_allocmy
#undef  pad_findmy
#define pad_findmy          pPerl->Perl_pad_findmy
#undef  op_const_sv
#define op_const_sv         pPerl->Perl_op_const_sv
#undef  op_free
#define op_free             pPerl->Perl_op_free
#undef  oopsCV
#define oopsCV              pPerl->Perl_oopsCV
#undef  oopsAV
#define oopsAV              pPerl->Perl_oopsAV
#undef  oopsHV
#define oopsHV              pPerl->Perl_oopsHV
#undef  opendir
#define opendir             pPerl->opendir
#undef  pad_leavemy
#define pad_leavemy         pPerl->Perl_pad_leavemy
#undef  pad_sv
#define pad_sv              pPerl->Perl_pad_sv
#undef  pad_findlex
#define pad_findlex         pPerl->pad_findlex
#undef  pad_free
#define pad_free            pPerl->Perl_pad_free
#undef  pad_reset
#define pad_reset           pPerl->Perl_pad_reset
#undef  pad_swipe
#define pad_swipe           pPerl->Perl_pad_swipe
#undef  peep
#define peep                pPerl->Perl_peep
#undef  perl_atexit
#define perl_atexit         pPerl->perl_atexit
#undef  perl_call_argv
#define perl_call_argv      pPerl->perl_call_argv
#undef  perl_call_method
#define perl_call_method    pPerl->perl_call_method
#undef  perl_call_pv
#define perl_call_pv        pPerl->perl_call_pv
#undef  perl_call_sv
#define perl_call_sv        pPerl->perl_call_sv
#undef  perl_callargv
#define perl_callargv       pPerl->perl_callargv
#undef  perl_callpv
#define perl_callpv         pPerl->perl_callpv
#undef  perl_callsv
#define perl_callsv         pPerl->perl_callsv
#undef  perl_eval_pv
#define perl_eval_pv        pPerl->perl_eval_pv
#undef  perl_eval_sv
#define perl_eval_sv        pPerl->perl_eval_sv
#undef  perl_get_sv
#define perl_get_sv         pPerl->perl_get_sv
#undef  perl_get_av
#define perl_get_av         pPerl->perl_get_av
#undef  perl_get_hv
#define perl_get_hv         pPerl->perl_get_hv
#undef  perl_get_cv
#define perl_get_cv         pPerl->perl_get_cv
#undef  perl_init_i18nl10n
#define perl_init_i18nl10n  pPerl->perl_init_i18nl10n
#undef  perl_init_i18nl14n
#define perl_init_i18nl14n  pPerl->perl_init_i18nl14n
#undef  perl_new_collate
#define perl_new_collate    pPerl->perl_new_collate
#undef  perl_new_ctype
#define perl_new_ctype      pPerl->perl_new_ctype
#undef  perl_new_numeric
#define perl_new_numeric    pPerl->perl_new_numeric
#undef  perl_set_numeric_local
#define perl_set_numeric_local pPerl->perl_set_numeric_local
#undef  perl_set_numeric_standard
#define perl_set_numeric_standard pPerl->perl_set_numeric_standard
#undef  perl_require_pv
#define perl_require_pv     pPerl->perl_require_pv
#undef  pidgone
#define pidgone             pPerl->Perl_pidgone
#undef  pmflag
#define pmflag              pPerl->Perl_pmflag
#undef  pmruntime
#define pmruntime           pPerl->Perl_pmruntime
#undef  pmtrans
#define pmtrans             pPerl->Perl_pmtrans
#undef  pop_return
#define pop_return          pPerl->Perl_pop_return
#undef  pop_scope
#define pop_scope           pPerl->Perl_pop_scope
#undef  prepend_elem
#define prepend_elem        pPerl->Perl_prepend_elem
#undef  push_return
#define push_return         pPerl->Perl_push_return
#undef  push_scope
#define push_scope          pPerl->Perl_push_scope
#undef  pregcomp
#define pregcomp            pPerl->Perl_pregcomp
#undef  ref
#define ref                 pPerl->Perl_ref
#undef  refkids
#define refkids             pPerl->Perl_refkids
#undef  regexec_flags
#define regexec_flags       pPerl->Perl_regexec_flags
#undef  pregexec
#define pregexec            pPerl->Perl_pregexec
#undef  pregfree
#define pregfree            pPerl->Perl_pregfree
#undef  regdump
#define regdump             pPerl->Perl_regdump
#undef  regnext
#define regnext             pPerl->Perl_regnext
#undef  regnoderegnext
#define regnoderegnext      pPerl->regnoderegnext
#undef  regprop
#define regprop             pPerl->Perl_regprop
#undef  repeatcpy
#define repeatcpy           pPerl->Perl_repeatcpy
#undef  rninstr
#define rninstr             pPerl->Perl_rninstr
#undef  rsignal
#define rsignal             pPerl->Perl_rsignal
#undef  rsignal_restore
#define rsignal_restore     pPerl->Perl_rsignal_restore
#undef  rsignal_save
#define rsignal_save        pPerl->Perl_rsignal_save
#undef  rsignal_state
#define rsignal_state       pPerl->Perl_rsignal_state
#undef  run
#define run                 pPerl->Perl_run
#undef  rxres_free
#define rxres_free          pPerl->Perl_rxres_free
#undef  rxres_restore
#define rxres_restore       pPerl->Perl_rxres_restore
#undef  rxres_save
#define rxres_save          pPerl->Perl_rxres_save
#undef  safefree
#define safefree            pPerl->Perl_safefree
#undef  safecalloc
#define safecalloc          pPerl->Perl_safecalloc
#undef  safemalloc
#define safemalloc          pPerl->Perl_safemalloc
#undef  saferealloc
#define saferealloc         pPerl->Perl_saferealloc
#undef  safexcalloc
#define safexcalloc         pPerl->Perl_safexcalloc
#undef  safexfree
#define safexfree           pPerl->Perl_safexfree
#undef  safexmalloc
#define safexmalloc         pPerl->Perl_safexmalloc
#undef  safexrealloc
#define safexrealloc        pPerl->Perl_safexrealloc
#undef  same_dirent
#define same_dirent         pPerl->Perl_same_dirent
#undef  savepv
#define savepv              pPerl->Perl_savepv
#undef  savepvn
#define savepvn             pPerl->Perl_savepvn
#undef  savestack_grow
#define savestack_grow      pPerl->Perl_savestack_grow
#undef  save_aelem
#define save_aelem          pPerl->Perl_save_aelem
#undef  save_aptr
#define save_aptr           pPerl->Perl_save_aptr
#undef  save_ary
#define save_ary            pPerl->Perl_save_ary
#undef  save_clearsv
#define save_clearsv        pPerl->Perl_save_clearsv
#undef  save_delete
#define save_delete         pPerl->Perl_save_delete
#undef  save_destructor
#define save_destructor     pPerl->Perl_save_destructor
#undef  save_freesv
#define save_freesv         pPerl->Perl_save_freesv
#undef  save_freeop
#define save_freeop         pPerl->Perl_save_freeop
#undef  save_freepv
#define save_freepv         pPerl->Perl_save_freepv
#undef  save_gp
#define save_gp             pPerl->Perl_save_gp
#undef  save_hash
#define save_hash           pPerl->Perl_save_hash
#undef  save_helem
#define save_helem          pPerl->Perl_save_helem
#undef  save_hints
#define save_hints          pPerl->Perl_save_hints
#undef  save_hptr
#define save_hptr           pPerl->Perl_save_hptr
#undef  save_I16
#define save_I16            pPerl->Perl_save_I16
#undef  save_I32
#define save_I32            pPerl->Perl_save_I32
#undef  save_int
#define save_int            pPerl->Perl_save_int
#undef  save_item
#define save_item           pPerl->Perl_save_item
#undef  save_iv
#define save_iv             pPerl->Perl_save_iv
#undef  save_list
#define save_list           pPerl->Perl_save_list
#undef  save_long
#define save_long           pPerl->Perl_save_long
#undef  save_nogv
#define save_nogv           pPerl->Perl_save_nogv
#undef  save_op
#define save_op             pPerl->Perl_save_op
#undef  save_scalar
#define save_scalar         pPerl->Perl_save_scalar
#undef  save_pptr
#define save_pptr           pPerl->Perl_save_pptr
#undef  save_sptr
#define save_sptr           pPerl->Perl_save_sptr
#undef  save_svref
#define save_svref          pPerl->Perl_save_svref
#undef  save_threadsv
#define save_threadsv       pPerl->Perl_save_threadsv
#undef  sawparens
#define sawparens           pPerl->Perl_sawparens
#undef  scalar
#define scalar              pPerl->Perl_scalar
#undef  scalarkids
#define scalarkids          pPerl->Perl_scalarkids
#undef  scalarseq
#define scalarseq           pPerl->Perl_scalarseq
#undef  scalarvoid
#define scalarvoid          pPerl->Perl_scalarvoid
#undef  scan_const
#define scan_const          pPerl->Perl_scan_const
#undef  scan_formline
#define scan_formline       pPerl->Perl_scan_formline
#undef  scan_ident
#define scan_ident          pPerl->Perl_scan_ident
#undef  scan_inputsymbol
#define scan_inputsymbol    pPerl->Perl_scan_inputsymbol
#undef  scan_heredoc
#define scan_heredoc        pPerl->Perl_scan_heredoc
#undef  scan_hex
#define scan_hex            pPerl->Perl_scan_hex
#undef  scan_num
#define scan_num            pPerl->Perl_scan_num
#undef  scan_oct
#define scan_oct            pPerl->Perl_scan_oct
#undef  scan_pat
#define scan_pat            pPerl->Perl_scan_pat
#undef  scan_str
#define scan_str            pPerl->Perl_scan_str
#undef  scan_subst
#define scan_subst          pPerl->Perl_scan_subst
#undef  scan_trans
#define scan_trans          pPerl->Perl_scan_trans
#undef  scope
#define scope               pPerl->Perl_scope
#undef  screaminstr
#define screaminstr         pPerl->Perl_screaminstr
#undef  setdefout
#define setdefout           pPerl->Perl_setdefout
#undef  setenv_getix
#define setenv_getix        pPerl->Perl_setenv_getix
#undef  share_hek
#define share_hek           pPerl->Perl_share_hek
#undef  sharepvn
#define sharepvn            pPerl->Perl_sharepvn
#undef  sighandler
#define sighandler          pPerl->Perl_sighandler
#undef  skipspace
#define skipspace           pPerl->Perl_skipspace
#undef  stack_grow
#define stack_grow          pPerl->Perl_stack_grow
#undef  start_subparse
#define start_subparse      pPerl->Perl_start_subparse
#undef  sub_crush_depth
#define sub_crush_depth     pPerl->Perl_sub_crush_depth
#undef  sublex_done
#define sublex_done         pPerl->Perl_sublex_done
#undef  sublex_start
#define sublex_start        pPerl->Perl_sublex_start
#undef  sv_2bool
#define sv_2bool	    pPerl->Perl_sv_2bool
#undef  sv_2cv
#define sv_2cv		    pPerl->Perl_sv_2cv
#undef  sv_2io
#define sv_2io		    pPerl->Perl_sv_2io
#undef  sv_2iv
#define sv_2iv		    pPerl->Perl_sv_2iv
#undef  sv_2mortal
#define sv_2mortal	    pPerl->Perl_sv_2mortal
#undef  sv_2nv
#define sv_2nv		    pPerl->Perl_sv_2nv
#undef  sv_2pv
#define sv_2pv		    pPerl->Perl_sv_2pv
#undef  sv_2uv
#define sv_2uv		    pPerl->Perl_sv_2uv
#undef  sv_add_arena
#define sv_add_arena	    pPerl->Perl_sv_add_arena
#undef  sv_backoff
#define sv_backoff	    pPerl->Perl_sv_backoff
#undef  sv_bless
#define sv_bless	    pPerl->Perl_sv_bless
#undef  sv_catpv
#define sv_catpv	    pPerl->Perl_sv_catpv
#undef  sv_catpvf
#define sv_catpvf	    pPerl->Perl_sv_catpvf
#undef  sv_catpvn
#define sv_catpvn	    pPerl->Perl_sv_catpvn
#undef  sv_catsv
#define sv_catsv	    pPerl->Perl_sv_catsv
#undef  sv_chop
#define sv_chop		    pPerl->Perl_sv_chop
#undef  sv_clean_all
#define sv_clean_all	    pPerl->Perl_sv_clean_all
#undef  sv_clean_objs
#define sv_clean_objs	    pPerl->Perl_sv_clean_objs
#undef  sv_clear
#define sv_clear	    pPerl->Perl_sv_clear
#undef  sv_cmp
#define sv_cmp		    pPerl->Perl_sv_cmp
#undef  sv_cmp_locale
#define sv_cmp_locale	    pPerl->Perl_sv_cmp_locale
#undef  sv_collxfrm
#define sv_collxfrm	    pPerl->Perl_sv_collxfrm
#undef  sv_compile_2op
#define sv_compile_2op	    pPerl->Perl_sv_compile_2op
#undef  sv_dec
#define sv_dec		    pPerl->Perl_sv_dec
#undef  sv_derived_from
#define sv_derived_from	    pPerl->Perl_sv_derived_from
#undef  sv_dump
#define sv_dump		    pPerl->Perl_sv_dump
#undef  sv_eq
#define sv_eq		    pPerl->Perl_sv_eq
#undef  sv_free
#define sv_free		    pPerl->Perl_sv_free
#undef  sv_free_arenas
#define sv_free_arenas	    pPerl->Perl_sv_free_arenas
#undef  sv_gets
#define sv_gets		    pPerl->Perl_sv_gets
#undef  sv_grow
#define sv_grow		    pPerl->Perl_sv_grow
#undef  sv_inc
#define sv_inc		    pPerl->Perl_sv_inc
#undef  sv_insert
#define sv_insert	    pPerl->Perl_sv_insert
#undef  sv_isa
#define sv_isa		    pPerl->Perl_sv_isa
#undef  sv_isobject
#define sv_isobject	    pPerl->Perl_sv_isobject
#undef  sv_iv
#define sv_iv		    pPerl->Perl_sv_iv
#undef  sv_len
#define sv_len		    pPerl->Perl_sv_len
#undef  sv_magic
#define sv_magic	    pPerl->Perl_sv_magic
#undef  sv_mortalcopy
#define sv_mortalcopy	    pPerl->Perl_sv_mortalcopy
#undef  sv_newmortal
#define sv_newmortal	    pPerl->Perl_sv_newmortal
#undef  sv_newref
#define sv_newref	    pPerl->Perl_sv_newref
#undef  sv_nv
#define sv_nv		    pPerl->Perl_sv_nv
#undef  sv_peek
#define sv_peek		    pPerl->Perl_sv_peek
#undef  sv_pvn
#define sv_pvn		    pPerl->Perl_sv_pvn
#undef  sv_pvn_force
#define sv_pvn_force	    pPerl->Perl_sv_pvn_force
#undef  sv_reftype
#define sv_reftype	    pPerl->Perl_sv_reftype
#undef  sv_replace
#define sv_replace	    pPerl->Perl_sv_replace
#undef  sv_report_used
#define sv_report_used	    pPerl->Perl_sv_report_used
#undef  sv_reset
#define sv_reset	    pPerl->Perl_sv_reset
#undef  sv_setiv
#define sv_setiv	    pPerl->Perl_sv_setiv
#undef  sv_setnv
#define sv_setnv	    pPerl->Perl_sv_setnv
#undef  sv_setpv
#define sv_setpv	    pPerl->Perl_sv_setpv
#undef  sv_setpvf
#define sv_setpvf	    pPerl->Perl_sv_setpvf
#undef  sv_setpviv
#define sv_setpviv	    pPerl->Perl_sv_setpviv
#undef  sv_setpvn
#define sv_setpvn	    pPerl->Perl_sv_setpvn
#undef  sv_setref_iv
#define sv_setref_iv	    pPerl->Perl_sv_setref_iv
#undef  sv_setref_nv
#define sv_setref_nv	    pPerl->Perl_sv_setref_nv
#undef  sv_setref_pv
#define sv_setref_pv	    pPerl->Perl_sv_setref_pv
#undef  sv_setref_pvn
#define sv_setref_pvn	    pPerl->Perl_sv_setref_pvn
#undef  sv_setsv
#define sv_setsv	    pPerl->Perl_sv_setsv
#undef  sv_setuv
#define sv_setuv	    pPerl->Perl_sv_setuv
#undef  sv_taint
#define sv_taint	    pPerl->Perl_sv_taint
#undef  sv_tainted
#define sv_tainted	    pPerl->Perl_sv_tainted
#undef  sv_true
#define sv_true		    pPerl->Perl_sv_true
#undef  sv_unmagic
#define sv_unmagic	    pPerl->Perl_sv_unmagic
#undef  sv_unref
#define sv_unref	    pPerl->Perl_sv_unref
#undef  sv_untaint
#define sv_untaint	    pPerl->Perl_sv_untaint
#undef  sv_upgrade
#define sv_upgrade	    pPerl->Perl_sv_upgrade
#undef  sv_usepvn
#define sv_usepvn	    pPerl->Perl_sv_usepvn
#undef  sv_uv
#define sv_uv		    pPerl->Perl_sv_uv
#undef  sv_vcatpvfn
#define sv_vcatpvfn	    pPerl->Perl_sv_vcatpvfn
#undef  sv_vsetpvfn
#define sv_vsetpvfn	    pPerl->Perl_sv_vsetpvfn
#undef  taint_env
#define taint_env	    pPerl->Perl_taint_env
#undef  taint_not
#define taint_not	    pPerl->Perl_taint_not
#undef  taint_proper
#define taint_proper	    pPerl->Perl_taint_proper
#undef  too_few_arguments
#define too_few_arguments   pPerl->Perl_too_few_arguments
#undef  too_many_arguments
#define too_many_arguments  pPerl->Perl_too_many_arguments
#undef  unlnk
#define unlnk               pPerl->Perl_unlnk
#undef  unlock_condpair
#define unlock_condpair     pPerl->Perl_unlock_condpair
#undef  unshare_hek
#define unshare_hek         pPerl->Perl_unshare_hek
#undef  unsharepvn
#define unsharepvn          pPerl->Perl_unsharepvn
#undef  utilize
#define utilize             pPerl->Perl_utilize
#undef  vivify_defelem
#define vivify_defelem      pPerl->Perl_vivify_defelem
#undef  vivify_ref
#define vivify_ref          pPerl->Perl_vivify_ref
#undef  wait4pid
#define wait4pid            pPerl->Perl_wait4pid
#undef  warn
#define warn    	    pPerl->Perl_warn
#undef  watch
#define watch    	    pPerl->Perl_watch
#undef  whichsig
#define whichsig            pPerl->Perl_whichsig
#undef  yyerror
#define yyerror             pPerl->Perl_yyerror
#undef  yylex
#define yylex               pPerl->Perl_yylex
#undef  yyparse
#define yyparse             pPerl->Perl_yyparse
#undef  yywarn
#define yywarn              pPerl->Perl_yywarn


#undef piMem
#define piMem               (pPerl->piMem)
#undef piENV
#define piENV               (pPerl->piENV)
#undef piStdIO
#define piStdIO             (pPerl->piStdIO)
#undef piLIO
#define piLIO               (pPerl->piLIO)
#undef piDir
#define piDir               (pPerl->piDir)
#undef piSock
#define piSock              (pPerl->piSock)
#undef piProc
#define piProc              (pPerl->piProc)

#ifndef NO_XSLOCKS
#undef closedir
#undef opendir
#undef stdin
#undef stdout
#undef stderr
#undef feof
#undef ferror
#undef fgetpos
#undef ioctl
#undef getlogin
#undef setjmp
#undef getc
#undef ungetc
#undef fileno

#define mkdir PerlDir_mkdir
#define chdir PerlDir_chdir
#define rmdir PerlDir_rmdir
#define closedir PerlDir_close
#define opendir PerlDir_open
#define readdir PerlDir_read
#define rewinddir PerlDir_rewind
#define seekdir PerlDir_seek
#define telldir PerlDir_tell
#define putenv PerlEnv_putenv
#define getenv PerlEnv_getenv
#define stdin PerlIO_stdin()
#define stdout PerlIO_stdout()
#define stderr PerlIO_stderr()
#define fopen PerlIO_open
#define fclose PerlIO_close
#define feof PerlIO_eof
#define ferror PerlIO_error
#define fclearerr PerlIO_clearerr
#define getc PerlIO_getc
#define fputc(c, f) PerlIO_putc(f,c)
#define fputs(s, f) PerlIO_puts(f,s)
#define fflush PerlIO_flush
#define ungetc(c, f) PerlIO_ungetc((f),(c))
#define fileno PerlIO_fileno
#define fdopen PerlIO_fdopen
#define freopen PerlIO_reopen
#define fread(b,s,c,f) PerlIO_read((f),(b),(s*c))
#define fwrite(b,s,c,f) PerlIO_write((f),(b),(s*c))
#define setbuf PerlIO_setbuf
#define setvbuf PerlIO_setvbuf
#define setlinebuf PerlIO_setlinebuf
#define stdoutf PerlIO_stdoutf
#define vfprintf PerlIO_vprintf
#define ftell PerlIO_tell
#define fseek PerlIO_seek
#define fgetpos PerlIO_getpos
#define fsetpos PerlIO_setpos
#define frewind PerlIO_rewind
#define tmpfile PerlIO_tmpfile
#define access PerlLIO_access
#define chmod PerlLIO_chmod
#define chsize PerlLIO_chsize
#define close PerlLIO_close
#define dup PerlLIO_dup
#define dup2 PerlLIO_dup2
#define flock PerlLIO_flock
#define fstat PerlLIO_fstat
#define ioctl PerlLIO_ioctl
#define isatty PerlLIO_isatty
#define lseek PerlLIO_lseek
#define lstat PerlLIO_lstat
#define mktemp PerlLIO_mktemp
#define open PerlLIO_open
#define read PerlLIO_read
#define rename PerlLIO_rename
#define setmode PerlLIO_setmode
#define stat PerlLIO_stat
#define tmpnam PerlLIO_tmpnam
#define umask PerlLIO_umask
#define unlink PerlLIO_unlink
#define utime PerlLIO_utime
#define write PerlLIO_write
#define malloc PerlMem_malloc
#define realloc PerlMem_realloc
#define free PerlMem_free
#define abort PerlProc_abort
#define exit PerlProc_exit
#define _exit PerlProc__exit
#define execl PerlProc_execl
#define execv PerlProc_execv
#define execvp PerlProc_execvp
#define getuid PerlProc_getuid
#define geteuid PerlProc_geteuid
#define getgid PerlProc_getgid
#define getegid PerlProc_getegid
#define getlogin PerlProc_getlogin
#define kill PerlProc_kill
#define killpg PerlProc_killpg
#define pause PerlProc_pause
#define popen PerlProc_popen
#define pclose PerlProc_pclose
#define pipe PerlProc_pipe
#define setuid PerlProc_setuid
#define setgid PerlProc_setgid
#define sleep PerlProc_sleep
#define times PerlProc_times
#define wait PerlProc_wait
#define setjmp PerlProc_setjmp
#define longjmp PerlProc_longjmp
#define signal PerlProc_signal
#define htonl PerlSock_htonl
#define htons PerlSock_htons
#define ntohs PerlSock_ntohl
#define ntohl PerlSock_ntohs
#define accept PerlSock_accept
#define bind PerlSock_bind
#define connect PerlSock_connect
#define endhostent PerlSock_endhostent
#define endnetent PerlSock_endnetent
#define endprotoent PerlSock_endprotoent
#define endservent PerlSock_endservent
#define gethostbyaddr PerlSock_gethostbyaddr
#define gethostbyname PerlSock_gethostbyname
#define gethostent PerlSock_gethostent
#define gethostname PerlSock_gethostname
#define getnetbyaddr PerlSock_getnetbyaddr
#define getnetbyname PerlSock_getnetbyname
#define getnetent PerlSock_getnetent
#define getpeername PerlSock_getpeername
#define getprotobyname PerlSock_getprotobyname
#define getprotobynumber PerlSock_getprotobynumber
#define getprotoent PerlSock_getprotoent
#define getservbyname PerlSock_getservbyname
#define getservbyport PerlSock_getservbyport
#define getservent PerlSock_getservent
#define getsockname PerlSock_getsockname
#define getsockopt PerlSock_getsockopt
#define inet_addr PerlSock_inet_addr
#define inet_ntoa PerlSock_inet_ntoa
#define listen PerlSock_listen
#define recvfrom PerlSock_recvfrom
#define select PerlSock_select
#define send PerlSock_send
#define sendto PerlSock_sendto
#define sethostent PerlSock_sethostent
#define setnetent PerlSock_setnetent
#define setprotoent PerlSock_setprotoent
#define setservent PerlSock_setservent
#define setsockopt PerlSock_setsockopt
#define shutdown PerlSock_shutdown
#define socket PerlSock_socket
#define socketpair PerlSock_socketpair
#endif  /* NO_XSLOCKS */

#undef  PERL_OBJECT_THIS
#define PERL_OBJECT_THIS pPerl
#undef  PERL_OBJECT_THIS_
#define PERL_OBJECT_THIS_ pPerl,

#undef  SAVEDESTRUCTOR
#define SAVEDESTRUCTOR(f,p) \
	pPerl->Perl_save_destructor((FUNC_NAME_TO_PTR(f)),(p))

#ifdef WIN32

#ifndef WIN32IO_IS_STDIO
#undef	errno
#define errno                 ErrorNo()
#endif

#undef  ErrorNo
#define ErrorNo				pPerl->ErrorNo
#undef  NtCrypt
#define NtCrypt               pPerl->NtCrypt
#undef  NtGetLib
#define NtGetLib              pPerl->NtGetLib
#undef  NtGetArchLib
#define NtGetArchLib          pPerl->NtGetArchLib
#undef  NtGetSiteLib
#define NtGetSiteLib          pPerl->NtGetSiteLib
#undef  NtGetBin
#define NtGetBin              pPerl->NtGetBin
#undef  NtGetDebugScriptStr
#define NtGetDebugScriptStr   pPerl->NtGetDebugScriptStr
#endif /* WIN32 */

#endif	/* __ObjXSub_h__ */ 

