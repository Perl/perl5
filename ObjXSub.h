#ifndef __ObjXSub_h__
#define __ObjXSub_h__

// variables
#undef  uid
#define uid					pPerl->Perl_uid
#undef  euid
#define euid				pPerl->Perl_euid
#undef  gid
#define gid					pPerl->Perl_gid
#undef  egid
#define egid				pPerl->Perl_egid
#undef  endav
#define endav               pPerl->Perl_endav
#undef  an
#define an					pPerl->Perl_an
#undef  compcv
#define compcv              pPerl->Perl_compcv
#undef  cop_seqmax
#define cop_seqmax			pPerl->Perl_cop_seqmax
#undef  defstash
#define defstash            pPerl->Perl_defstash
#undef  evalseq
#define evalseq				pPerl->Perl_evalseq
#undef  hexdigit
#define hexdigit            pPerl->Perl_hexdigit
#undef  sub_generation
#define sub_generation		pPerl->Perl_sub_generation
#undef  origenviron
#define origenviron			pPerl->Perl_origenviron
#undef  environ
#define environ				pPerl->Perl_environ
#undef  origalen
#define origalen			pPerl->Perl_origalen
#undef  profiledata
#define profiledata			pPerl->Perl_profiledata
#undef  xiv_arenaroot
#define xiv_arenaroot		pPerl->Perl_xiv_arenaroot
#undef  xiv_root
#define xiv_root			pPerl->Perl_xiv_root
#undef  xnv_root
#define xnv_root			pPerl->Perl_xnv_root
#undef  xrv_root
#define xrv_root			pPerl->Perl_xrv_root
#undef  xpv_root
#define xpv_root			pPerl->Perl_xpv_root
#undef  stack_base
#define stack_base			pPerl->Perl_stack_base
#undef  stack_sp
#define stack_sp			pPerl->Perl_stack_sp
#undef  stack_max
#define stack_max			pPerl->Perl_stack_max
#undef  op
#define op		 			pPerl->Perl_op
#undef  scopestack
#define scopestack			pPerl->Perl_scopestack
#undef  scopestack_ix
#define scopestack_ix		pPerl->Perl_scopestack_ix
#undef  scopestack_max
#define scopestack_max		pPerl->Perl_scopestack_max
#undef  savestack
#define savestack			pPerl->Perl_savestack
#undef  savestack_ix
#define savestack_ix		pPerl->Perl_savestack_ix
#undef  savestack_max
#define savestack_max		pPerl->Perl_savestack_max
#undef  retstack
#define retstack			pPerl->Perl_retstack
#undef  retstack_ix
#define retstack_ix			pPerl->Perl_retstack_ix
#undef  retstack_max
#define retstack_max		pPerl->Perl_retstack_max
#undef  markstack
#define markstack			pPerl->Perl_markstack
#undef  markstack_ptr
#define markstack_ptr		pPerl->Perl_markstack_ptr
#undef  markstack_max
#define markstack_max		pPerl->Perl_markstack_max
#undef  maxo
#define maxo                pPerl->Perl_maxo
#undef  op_mask
#define op_mask             pPerl->Perl_op_mask
#undef  curpad
#define curpad				pPerl->Perl_curpad
#undef  Sv
#define Sv					pPerl->Perl_Sv
#undef  Xpv
#define Xpv					pPerl->Perl_Xpv
#undef  tokenbuf
#define tokenbuf			pPerl->Perl_tokenbuf
#undef  statbuf
#define statbuf				pPerl->Perl_statbuf
#undef  timesbuf
#define timesbuf			pPerl->Perl_timesbuf
#undef  di
#define di					pPerl->Perl_di
#undef  ds
#define ds					pPerl->Perl_ds
#undef  dc
#define dc					pPerl->Perl_dc
#undef  sv_undef
#define sv_undef			pPerl->Perl_sv_undef
#undef  sv_no
#define sv_no				pPerl->Perl_sv_no
#undef  sv_yes
#define sv_yes				pPerl->Perl_sv_yes
#undef  na
#define na					pPerl->Perl_na

#undef  yydebug
#define yydebug				pPerl->Perl_yydebug
#undef  yynerrs
#define yynerrs				pPerl->Perl_yynerrs
#undef  yyerrflag
#define yyerrflag			pPerl->Perl_yyerrflag
#undef  yychar
#define yychar				pPerl->Perl_yychar
#undef  yyval
#define yyval				pPerl->Perl_yyval
#undef  yylval
#define yylval				pPerl->Perl_yylval
#undef  last_hkey
#define last_hkey			pPerl->Perl_last_hkey
#undef  valbuf
#define valbuf				pPerl->Perl_valbuf
#undef  namebuf
#define namebuf				pPerl->Perl_namebuf
#undef  maxvalsz
#define maxvalsz			pPerl->Perl_maxvalsz
#undef  maxnamesz
#define maxnamesz			pPerl->Perl_maxnamesz

// functions

#undef  amagic_call
#define amagic_call         pPerl->Perl_amagic_call
#undef  Gv_AMupdate
#define Gv_AMupdate         pPerl->Gv_AMupdate
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
#undef  av_shift
#define av_shift            pPerl->Perl_av_shift
#undef  av_store
#define av_store            pPerl->Perl_av_store
#undef  av_undef
#define av_undef            pPerl->Perl_av_undef
#undef  av_unshift
#define av_unshift          pPerl->Perl_av_unshift
#undef  bad_type
#define bad_type            pPerl->bad_type
#undef  bind_match
#define bind_match          pPerl->Perl_bind_match
#undef  block_end
#define block_end           pPerl->Perl_block_end
#undef  block_start
#define block_start         pPerl->Perl_block_start
#undef  call_list
#define call_list           pPerl->Perl_call_list
#undef  cando
#define cando               pPerl->Perl_cando
#undef  cast_ulong
#define cast_ulong          pPerl->cast_ulong
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
#undef  closedir
#define closedir            pPerl->closedir
#undef  convert
#define convert             pPerl->Perl_convert
#undef  cpytill
#define cpytill             pPerl->Perl_cpytill
#undef  croak
#define croak               pPerl->Perl_croak
#undef  cv_clone
#define cv_clone            pPerl->Perl_cv_clone
#undef  cv_undef
#define cv_undef            pPerl->Perl_cv_undef
#undef  cxinc
#define cxinc               pPerl->Perl_cxinc
#undef  del_xiv
#define del_xiv             pPerl->del_xiv
#undef  del_xnv
#define del_xnv             pPerl->del_xnv
#undef  del_xpv
#define del_xpv             pPerl->del_xpv
#undef  del_xrv
#define del_xrv             pPerl->del_xrv
#undef  deprecate
#define deprecate           pPerl->Perl_deprecate
#undef  die
#define die                 pPerl->Perl_die
#undef  die_where
#define die_where           pPerl->Perl_die_where
#undef  doencodes
#define doencodes           pPerl->doencodes
#undef  doform
#define doform              pPerl->doform
#undef  doparseform
#define doparseform         pPerl->doparseform
#undef  dopoptoeval
#define dopoptoeval         pPerl->Perl_dopoptoeval
#undef  dopoptolabel
#define dopoptolabel        pPerl->dopoptolabel
#undef  dopoptoloop
#define dopoptoloop         pPerl->dopoptoloop
#undef  dopoptosub
#define dopoptosub          pPerl->dopoptosub
#undef  dounwind
#define dounwind            pPerl->Perl_dounwind
#undef  do_aexec
#define do_aexec            pPerl->Perl_do_aexec
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
#undef  do_open
#define do_open             pPerl->Perl_do_open
#undef  dowantarray
#define dowantarray         pPerl->Perl_dowantarray
#undef  fbm_compile
#define fbm_compile         pPerl->Perl_fbm_compile
#undef  fbm_instr
#define fbm_instr           pPerl->Perl_fbm_instr
#undef  filter_add
#define filter_add          pPerl->Perl_filter_add
#undef  filter_del
#define filter_del          pPerl->Perl_filter_del
#undef  filter_gets
#define filter_gets         pPerl->filter_gets
#undef  filter_read
#define filter_read         pPerl->Perl_filter_read
#undef  find_beginning
#define find_beginning      pPerl->find_beginning
#undef  force_ident
#define force_ident         pPerl->Perl_force_ident
#undef  force_list
#define force_list          pPerl->Perl_force_list
#undef  force_next
#define force_next          pPerl->Perl_force_next
#undef  force_word
#define force_word          pPerl->Perl_force_word
#undef  fold_constants
#define fold_constants      pPerl->Perl_fold_constants
#undef  fprintf
#define fprintf             pPerl->fprintf
#undef  free_tmps
#define free_tmps           pPerl->Perl_free_tmps
#undef  gen_constant_list
#define gen_constant_list   pPerl->Perl_gen_constant_list
#undef  getlogin
#define getlogin            pPerl->getlogin
#undef  get_op_descs
#define get_op_descs        pPerl->Perl_get_op_descs
#undef  get_op_names
#define get_op_names        pPerl->Perl_get_op_names
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
#undef  gv_init_sv
#define gv_init_sv          pPerl->gv_init_sv
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
#undef  hfreeentries
#define hfreeentries        pPerl->hfreeentries
#undef  hoistmust
#define hoistmust           pPerl->Perl_hoistmust
#undef  hsplit
#define hsplit              pPerl->hsplit
#undef  hv_clear
#define hv_clear            pPerl->Perl_hv_clear
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
#undef  incpush
#define incpush             pPerl->incpush
#undef  incline
#define incline             pPerl->incline
#undef  incl_perldb
#define incl_perldb         pPerl->incl_perldb
#undef  ingroup
#define ingroup             pPerl->Perl_ingroup
#undef  instr
#define instr               pPerl->Perl_instr
#undef  intuit_method
#define intuit_method       pPerl->intuit_method
#undef  intuit_more
#define intuit_more         pPerl->Perl_intuit_more
#undef  invert
#define invert              pPerl->Perl_invert
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
#undef  magic_clearenv
#define magic_clearenv      pPerl->Perl_magic_clearenv
#undef  magic_clearpack
#define magic_clearpack     pPerl->Perl_magic_clearpack
#undef  magic_clearsig
#define magic_clearsig      pPerl->Perl_magic_clearsig
#undef  magic_existspack
#define magic_existspack    pPerl->Perl_magic_existspack
#undef  magic_get
#define magic_get           pPerl->Perl_magic_get
#undef  magic_getarylen
#define magic_getarylen     pPerl->Perl_magic_getarylen
#undef  magic_getpack
#define magic_getpack       pPerl->Perl_magic_getpack
#undef  magic_getglob
#define magic_getglob       pPerl->Perl_magic_getglob
#undef  magic_getpos
#define magic_getpos        pPerl->Perl_magic_getpos
#undef  magic_getsig
#define magic_getsig        pPerl->Perl_magic_getsig
#undef  magic_gettaint
#define magic_gettaint      pPerl->Perl_magic_gettaint
#undef  magic_getuvar
#define magic_getuvar       pPerl->Perl_magic_getuvar
#undef  magic_len
#define magic_len           pPerl->Perl_magic_len
#undef  magic_methpack
#define magic_methpack      pPerl->magic_methpack
#undef  magic_nextpack
#define magic_nextpack      pPerl->Perl_magic_nextpack
#undef  magic_set
#define magic_set           pPerl->Perl_magic_set
#undef  magic_setamagic
#define magic_setamagic     pPerl->Perl_magic_setamagic
#undef  magic_setarylen
#define magic_setarylen     pPerl->Perl_magic_setarylen
#undef  magic_setbm
#define magic_setbm         pPerl->Perl_magic_setbm
#undef  magic_setdbline
#define magic_setdbline     pPerl->Perl_magic_setdbline
#undef  magic_setenv
#define magic_setenv        pPerl->Perl_magic_setenv
#undef  magic_setisa
#define magic_setisa          pPerl->Perl_magic_setisa
#undef  magic_setglob
#define magic_setglob         pPerl->Perl_magic_setglob
#undef  magic_setmglob
#define magic_setmglob        pPerl->Perl_magic_setmglob
#undef  magic_setnkeys
#define magic_setnkeys        pPerl->Perl_magic_setnkeys
#undef  magic_setpack
#define magic_setpack         pPerl->Perl_magic_setpack
#undef  magic_setpos
#define magic_setpos          pPerl->Perl_magic_setpos
#undef  magic_setsig
#define magic_setsig          pPerl->Perl_magic_setsig
#undef  magic_setsubstr
#define magic_setsubstr       pPerl->Perl_magic_setsubstr
#undef  magic_settaint
#define magic_settaint        pPerl->Perl_magic_settaint
#undef  magic_setuvar
#define magic_setuvar         pPerl->Perl_magic_setuvar
#undef  magic_setvec
#define magic_setvec          pPerl->Perl_magic_setvec
#undef  magic_wipepack
#define magic_wipepack        pPerl->Perl_magic_wipepack
#undef  magicname
#define magicname             pPerl->Perl_magicname
#undef  markstack_grow
#define markstack_grow        pPerl->Perl_markstack_grow
#undef  mess
#define mess                  pPerl->Perl_mess
#undef  mg_clear
#define mg_clear              pPerl->Perl_mg_clear
#undef  mg_copy
#define mg_copy               pPerl->Perl_mg_copy
#undef  mg_find
#define mg_find               pPerl->Perl_mg_find
#undef  mg_free
#define mg_free               pPerl->Perl_mg_free
#undef  mg_get
#define mg_get                pPerl->Perl_mg_get
#undef  mg_magical
#define mg_magical            pPerl->Perl_mg_magical
#undef  mg_set
#define mg_set                pPerl->Perl_mg_set
#undef  missingterm
#define missingterm           pPerl->missingterm
#undef  mod
#define mod                   pPerl->Perl_mod
#undef  modkids
#define modkids               pPerl->Perl_modkids
#undef  moreswitches
#define moreswitches          pPerl->Perl_moreswitches
#undef  more_sv
#define more_sv               pPerl->more_sv
#undef  more_xiv
#define more_xiv              pPerl->more_xiv
#undef  more_xnv
#define more_xnv              pPerl->more_xnv
#undef  more_xpv
#define more_xpv              pPerl->more_xpv
#undef  more_xrv
#define more_xrv              pPerl->more_xrv
#undef  my
#define my                    pPerl->Perl_my
#undef  my_bcopy
#define my_bcopy              pPerl->Perl_my_bcopy
#undef  my_bzero
#define my_bzero              pPerl->Perl_my_bzero
#undef  my_exit
#define my_exit               pPerl->Perl_my_exit
#undef  my_lstat
#define my_lstat              pPerl->Perl_my_lstat
#undef  my_memcmp
#define my_memcmp             pPerl->my_memcmp
#undef  my_pclose
#define my_pclose             pPerl->Perl_my_pclose
#undef  my_popen
#define my_popen              pPerl->Perl_my_popen
#undef  my_setenv
#define my_setenv             pPerl->Perl_my_setenv
#undef  my_stat
#define my_stat               pPerl->Perl_my_stat
#undef  my_unexec
#define my_unexec             pPerl->Perl_my_unexec
#undef  newANONLIST
#define newANONLIST           pPerl->Perl_newANONLIST
#undef  newANONHASH
#define newANONHASH           pPerl->Perl_newANONHASH
#undef  newANONSUB
#define newANONSUB            pPerl->Perl_newANONSUB
#undef  newASSIGNOP
#define newASSIGNOP           pPerl->Perl_newASSIGNOP
#undef  newCONDOP
#define newCONDOP             pPerl->Perl_newCONDOP
#undef  newFORM
#define newFORM               pPerl->Perl_newFORM
#undef  newFOROP
#define newFOROP              pPerl->Perl_newFOROP
#undef  newLOGOP
#define newLOGOP              pPerl->Perl_newLOGOP
#undef  newLOOPEX
#define newLOOPEX             pPerl->Perl_newLOOPEX
#undef  newLOOPOP
#define newLOOPOP             pPerl->Perl_newLOOPOP
#undef  newMETHOD
#define newMETHOD             pPerl->Perl_newMETHOD
#undef  newNULLLIST
#define newNULLLIST           pPerl->Perl_newNULLLIST
#undef  newOP
#define newOP                 pPerl->Perl_newOP
#undef  newPROG
#define newPROG               pPerl->Perl_newPROG
#undef  newRANGE
#define newRANGE              pPerl->Perl_newRANGE
#undef  newSLICEOP
#define newSLICEOP            pPerl->Perl_newSLICEOP
#undef  newSTATEOP
#define newSTATEOP            pPerl->Perl_newSTATEOP
#undef  newSUB
#define newSUB                pPerl->Perl_newSUB
#undef  newXS
#define newXS                 pPerl->Perl_newXS
#undef  newAV
#define newAV                 pPerl->Perl_newAV
#undef  newAVREF
#define newAVREF              pPerl->Perl_newAVREF
#undef  newBINOP
#define newBINOP              pPerl->Perl_newBINOP
#undef  newCVREF
#define newCVREF              pPerl->Perl_newCVREF
#undef  newCVOP
#define newCVOP               pPerl->Perl_newCVOP
#undef  newGVOP
#define newGVOP               pPerl->Perl_newGVOP
#undef  newGVgen
#define newGVgen              pPerl->Perl_newGVgen
#undef  newGVREF
#define newGVREF              pPerl->Perl_newGVREF
#undef  newHVREF
#define newHVREF              pPerl->Perl_newHVREF
#undef  newHV
#define newHV                 pPerl->Perl_newHV
#undef  newIO
#define newIO                 pPerl->Perl_newIO
#undef  newLISTOP
#define newLISTOP             pPerl->Perl_newLISTOP
#undef  newPMOP
#define newPMOP               pPerl->Perl_newPMOP
#undef  newPVOP
#define newPVOP               pPerl->Perl_newPVOP
#undef  newRV
#define newRV                 pPerl->Perl_newRV
#undef  newSV
#define newSV                 pPerl->Perl_newSV
#undef  newSV
#define newSV                 pPerl->Perl_newSV
#undef  newSVREF
#define newSVREF              pPerl->Perl_newSVREF
#undef  newSVOP
#define newSVOP               pPerl->Perl_newSVOP
#undef  newSViv
#define newSViv               pPerl->Perl_newSViv
#undef  newSVnv
#define newSVnv               pPerl->Perl_newSVnv
#undef  newSVpv
#define newSVpv               pPerl->Perl_newSVpv
#undef  newSVrv
#define newSVrv               pPerl->Perl_newSVrv
#undef  newSVsv
#define newSVsv               pPerl->Perl_newSVsv
#undef  newUNOP
#define newUNOP               pPerl->Perl_newUNOP
#undef  newWHILEOP
#define newWHILEOP            pPerl->Perl_newWHILEOP
#undef  new_sv
#define new_sv                pPerl->new_sv
#undef  new_xiv
#define new_xiv               pPerl->new_xiv
#undef  new_xnv
#define new_xnv               pPerl->new_xnv
#undef  new_xpv
#define new_xpv               pPerl->new_xpv
#undef  new_xrv
#define new_xrv               pPerl->new_xrv
#undef  nextargv
#define nextargv              pPerl->Perl_nextargv
#undef  nextchar
#define nextchar              pPerl->nextchar
#undef  ninstr
#define ninstr                pPerl->Perl_ninstr
#undef  not_a_number
#define not_a_number          pPerl->not_a_number
#undef  no_fh_allowed
#define no_fh_allowed         pPerl->Perl_no_fh_allowed
#undef  no_op
#define no_op                 pPerl->Perl_no_op
#undef  null
#define null                  pPerl->null
#undef  package
#define package               pPerl->Perl_package
#undef  pad_allocmy
#define pad_allocmy           pPerl->Perl_pad_allocmy
#undef  pad_findmy
#define pad_findmy            pPerl->Perl_pad_findmy
#undef  op_free
#define op_free               pPerl->Perl_op_free
#undef  oopsCV
#define oopsCV                pPerl->Perl_oopsCV
#undef  oopsAV
#define oopsAV                pPerl->Perl_oopsAV
#undef  oopsHV
#define oopsHV                pPerl->Perl_oopsHV
#undef  opendir
#define opendir               pPerl->opendir
#undef  open_script
#define open_script           pPerl->open_script
#undef  pad_leavemy
#define pad_leavemy           pPerl->Perl_pad_leavemy
#undef  pad_sv
#define pad_sv                pPerl->Perl_pad_sv
#undef  pad_findlex
#define pad_findlex           pPerl->pad_findlex
#undef  pad_free
#define pad_free              pPerl->Perl_pad_free
#undef  pad_reset
#define pad_reset             pPerl->Perl_pad_reset
#undef  pad_swipe
#define pad_swipe             pPerl->Perl_pad_swipe
#undef  peep
#define peep                  pPerl->Perl_peep
#undef  perl_call_argv
#define perl_call_argv        pPerl->perl_call_argv
#undef  perl_call_method
#define perl_call_method      pPerl->perl_call_method
#undef  perl_call_pv
#define perl_call_pv          pPerl->perl_call_pv
#undef  perl_call_sv
#define perl_call_sv          pPerl->perl_call_sv
#undef  perl_callargv
#define perl_callargv         pPerl->perl_callargv
#undef  perl_callpv
#define perl_callpv           pPerl->perl_callpv
#undef  perl_callsv
#define perl_callsv           pPerl->perl_callsv
#undef  perl_eval_sv
#define perl_eval_sv          pPerl->perl_eval_sv
#undef  perl_get_sv
#define perl_get_sv           pPerl->perl_get_sv
#undef  perl_get_av
#define perl_get_av           pPerl->perl_get_av
#undef  perl_get_hv
#define perl_get_hv           pPerl->perl_get_hv
#undef  perl_get_cv
#define perl_get_cv           pPerl->perl_get_cv
#undef  perl_require_pv
#define perl_require_pv       pPerl->perl_require_pv
#undef  pidgone
#define pidgone               pPerl->Perl_pidgone
#undef  pmflag
#define pmflag                pPerl->Perl_pmflag
#undef  pmruntime
#define pmruntime             pPerl->Perl_pmruntime
#undef  pmtrans
#define pmtrans               pPerl->Perl_pmtrans
#undef  pop_return
#define pop_return            pPerl->Perl_pop_return
#undef  pop_scope
#define pop_scope             pPerl->Perl_pop_scope
#undef  prepend_elem
#define prepend_elem          pPerl->Perl_prepend_elem
#undef  push_return
#define push_return           pPerl->Perl_push_return
#undef  push_scope
#define push_scope            pPerl->Perl_push_scope
#undef  pregcomp
#define pregcomp              pPerl->Perl_pregcomp
#undef  ref
#define ref                   pPerl->Perl_ref
#undef  refkids
#define refkids               pPerl->Perl_refkids
#undef  pregexec
#define pregexec              pPerl->Perl_pregexec
#undef  pregfree
#define pregfree              pPerl->Perl_pregfree
#undef  reganode
#define reganode              pPerl->reganode
#undef  regatom
#define regatom               pPerl->regatom
#undef  regbranch
#define regbranch             pPerl->regbranch
#undef  regc
#define regc                  pPerl->regc
#undef  regclass
#define regclass              pPerl->regclass
#undef  regcppush
#define regcppush             pPerl->regcppush
#undef  regcppop
#define regcppop              pPerl->regcppop
#undef  reginsert
#define reginsert             pPerl->reginsert
#undef  regmatch
#define regmatch              pPerl->regmatch
#undef  regnext
#define regnext               pPerl->Perl_regnext
#undef  regoptail
#define regoptail             pPerl->regoptail
#undef  regpiece
#define regpiece              pPerl->regpiece
#undef  regrepeat
#define regrepeat             pPerl->regrepeat
#undef  regset
#define regset                pPerl->regset
#undef  regtail
#define regtail               pPerl->regtail
#undef  regtry
#define regtry                pPerl->regtry
#undef  repeatcpy
#define repeatcpy             pPerl->Perl_repeatcpy
#undef  rninstr
#define rninstr               pPerl->Perl_rninstr
#undef  run
#define run                   pPerl->Perl_run
#undef  safefree
#define safefree              pPerl->Perl_safefree
#undef  safecalloc
#define safecalloc            pPerl->Perl_safecalloc
#undef  safemalloc
#define safemalloc            pPerl->Perl_safemalloc
#undef  saferealloc
#define saferealloc           pPerl->Perl_saferealloc
#undef  same_dirent
#define same_dirent           pPerl->same_dirent
#undef  savepv
#define savepv                pPerl->Perl_savepv
#undef  savepvn
#define savepvn               pPerl->Perl_savepvn
#undef  savestack_grow
#define savestack_grow        pPerl->Perl_savestack_grow
#undef  save_aptr
#define save_aptr             pPerl->Perl_save_aptr
#undef  save_ary
#define save_ary              pPerl->Perl_save_ary
#undef  save_clearsv
#define save_clearsv          pPerl->Perl_save_clearsv
#undef  save_delete
#define save_delete           pPerl->Perl_save_delete
#undef  save_destructor
#define save_destructor       pPerl->Perl_save_destructor
#undef  save_freesv
#define save_freesv           pPerl->Perl_save_freesv
#undef  save_freeop
#define save_freeop           pPerl->Perl_save_freeop
#undef  save_freepv
#define save_freepv           pPerl->Perl_save_freepv
#undef  save_hash
#define save_hash             pPerl->Perl_save_hash
#undef  save_hptr
#define save_hptr             pPerl->Perl_save_hptr
#undef  save_I32
#define save_I32              pPerl->Perl_save_I32
#undef  save_int
#define save_int              pPerl->Perl_save_int
#undef  save_item
#define save_item             pPerl->Perl_save_item
#undef  save_iv
#define save_iv               pPerl->save_iv
#undef  save_lines
#define save_lines            pPerl->save_lines
#undef  save_list
#define save_list             pPerl->Perl_save_list
#undef  save_long
#define save_long             pPerl->Perl_save_long
#undef  save_nogv
#define save_nogv             pPerl->Perl_save_nogv
#undef  save_scalar
#define save_scalar           pPerl->Perl_save_scalar
#undef  save_pptr
#define save_pptr             pPerl->Perl_save_pptr
#undef  save_sptr
#define save_sptr             pPerl->Perl_save_sptr
#undef  save_svref
#define save_svref            pPerl->Perl_save_svref
#undef  sawparens
#define sawparens             pPerl->Perl_sawparens
#undef  scalar
#define scalar                pPerl->Perl_scalar
#undef  scalarboolean
#define scalarboolean         pPerl->scalarboolean
#undef  scalarkids
#define scalarkids            pPerl->Perl_scalarkids
#undef  scalarseq
#define scalarseq             pPerl->Perl_scalarseq
#undef  scalarvoid
#define scalarvoid            pPerl->Perl_scalarvoid
#undef  scan_const
#define scan_const            pPerl->Perl_scan_const
#undef  scan_formline
#define scan_formline         pPerl->Perl_scan_formline
#undef  scan_ident
#define scan_ident            pPerl->Perl_scan_ident
#undef  scan_inputsymbol
#define scan_inputsymbol      pPerl->Perl_scan_inputsymbol
#undef  scan_heredoc
#define scan_heredoc          pPerl->Perl_scan_heredoc
#undef  scan_hex
#define scan_hex              pPerl->Perl_scan_hex
#undef  scan_num
#define scan_num              pPerl->Perl_scan_num
#undef  scan_oct
#define scan_oct              pPerl->Perl_scan_oct
#undef  scan_pat
#define scan_pat              pPerl->Perl_scan_pat
#undef  scan_str
#define scan_str              pPerl->Perl_scan_str
#undef  scan_subst
#define scan_subst            pPerl->Perl_scan_subst
#undef  scan_trans
#define scan_trans            pPerl->Perl_scan_trans
#undef  scope
#define scope                 pPerl->Perl_scope
#undef  screaminstr
#define screaminstr           pPerl->Perl_screaminstr
#undef  sighandler
#define sighandler            pPerl->Perl_sighandler
#undef  skipspace
#define skipspace             pPerl->Perl_skipspace
#undef  stack_grow
#define stack_grow            pPerl->Perl_stack_grow
#undef  start_subparse
#define start_subparse        pPerl->Perl_start_subparse
#undef  sublex_done
#define sublex_done           pPerl->Perl_sublex_done
#undef  sublex_start
#define sublex_start          pPerl->Perl_sublex_start
#undef  sv_2bool
#define sv_2bool              pPerl->Perl_sv_2bool
#undef  sv_2cv
#define sv_2cv                pPerl->Perl_sv_2cv
#undef  sv_2io
#define sv_2io                pPerl->Perl_sv_2io
#undef  sv_2iv
#define sv_2iv                pPerl->Perl_sv_2iv
#undef  sv_2mortal
#define sv_2mortal            pPerl->Perl_sv_2mortal
#undef  sv_2nv
#define sv_2nv                pPerl->Perl_sv_2nv
#undef  sv_2pv
#define sv_2pv                pPerl->Perl_sv_2pv
#undef  sv_add_arena
#define sv_add_arena          pPerl->Perl_sv_add_arena
#undef  sv_backoff
#define sv_backoff            pPerl->Perl_sv_backoff
#undef  sv_bless
#define sv_bless              pPerl->Perl_sv_bless
#undef  sv_catpv
#define sv_catpv              pPerl->Perl_sv_catpv
#undef  sv_catpvn
#define sv_catpvn             pPerl->Perl_sv_catpvn
#undef  sv_catsv
#define sv_catsv              pPerl->Perl_sv_catsv
#undef  sv_chop
#define sv_chop               pPerl->Perl_sv_chop
#undef  sv_clean_all
#define sv_clean_all          pPerl->Perl_sv_clean_all
#undef  sv_clean_objs
#define sv_clean_objs         pPerl->Perl_sv_clean_objs
#undef  sv_clear
#define sv_clear              pPerl->Perl_sv_clear
#undef  sv_cmp
#define sv_cmp                pPerl->Perl_sv_cmp
#undef  sv_dec
#define sv_dec                pPerl->Perl_sv_dec
#undef  sv_derived_from
#define sv_derived_from       pPerl->Perl_sv_derived_from
#undef  sv_dump
#define sv_dump               pPerl->Perl_sv_dump
#undef  sv_eq
#define sv_eq                 pPerl->Perl_sv_eq
#undef  sv_free
#define sv_free               pPerl->Perl_sv_free
#undef  sv_free_arenas
#define sv_free_arenas        pPerl->Perl_sv_free_arenas
#undef  sv_gets
#define sv_gets               pPerl->Perl_sv_gets
#undef  sv_grow
#define sv_grow               pPerl->Perl_sv_grow
#undef  sv_inc
#define sv_inc                pPerl->Perl_sv_inc
#undef  sv_insert
#define sv_insert             pPerl->Perl_sv_insert
#undef  sv_isa
#define sv_isa                pPerl->Perl_sv_isa
#undef  sv_isobject
#define sv_isobject           pPerl->Perl_sv_isobject
#undef  sv_len
#define sv_len                pPerl->Perl_sv_len
#undef  sv_magic
#define sv_magic              pPerl->Perl_sv_magic
#undef  sv_mortalcopy
#define sv_mortalcopy         pPerl->Perl_sv_mortalcopy
#undef  sv_mortalgrow
#define sv_mortalgrow         pPerl->sv_mortalgrow
#undef  sv_newmortal
#define sv_newmortal          pPerl->Perl_sv_newmortal
#undef  sv_newref
#define sv_newref             pPerl->Perl_sv_newref
#undef  sv_pvn
#define sv_pvn                pPerl->Perl_sv_pvn
#undef  sv_pvn_force
#define sv_pvn_force          pPerl->Perl_sv_pvn_force
#undef  sv_reftype
#define sv_reftype            pPerl->Perl_sv_reftype
#undef  sv_replace
#define sv_replace            pPerl->Perl_sv_replace
#undef  sv_report_used
#define sv_report_used        pPerl->Perl_sv_report_used
#undef  sv_reset
#define sv_reset              pPerl->Perl_sv_reset
#undef  sv_setiv
#define sv_setiv              pPerl->Perl_sv_setiv
#undef  sv_setnv
#define sv_setnv              pPerl->Perl_sv_setnv
#undef  sv_setref_iv
#define sv_setref_iv          pPerl->Perl_sv_setref_iv
#undef  sv_setref_nv
#define sv_setref_nv          pPerl->Perl_sv_setref_nv
#undef  sv_setref_pv
#define sv_setref_pv          pPerl->Perl_sv_setref_pv
#undef  sv_setref_pvn
#define sv_setref_pvn         pPerl->Perl_sv_setref_pvn
#undef  sv_setpv
#define sv_setpv              pPerl->Perl_sv_setpv
#undef  sv_setpvn
#define sv_setpvn             pPerl->Perl_sv_setpvn
#undef  sv_setsv
#define sv_setsv              pPerl->Perl_sv_setsv
#undef  sv_unglob
#define sv_unglob             pPerl->sv_unglob
#undef  sv_unmagic
#define sv_unmagic            pPerl->Perl_sv_unmagic
#undef  sv_unref
#define sv_unref              pPerl->Perl_sv_unref
#undef  sv_upgrade
#define sv_upgrade            pPerl->Perl_sv_upgrade
#undef  sv_usepvn
#define sv_usepvn             pPerl->Perl_sv_usepvn
#undef  taint_env
#define taint_env			pPerl->Perl_taint_env
#undef  taint_not
#define taint_not			pPerl->Perl_taint_not
#undef  taint_proper
#define taint_proper		pPerl->Perl_taint_proper
#undef  too_few_arguments
#define too_few_arguments	pPerl->Perl_too_few_arguments
#undef  too_many_arguments
#define too_many_arguments	pPerl->Perl_too_many_arguments
#undef  warn
#define warn    			pPerl->Perl_warn


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

#undef SAVETMPS
#define SAVETMPS			pPerl->SaveTmps()
#undef FREETMPS
#define FREETMPS			pPerl->FreeTmps()

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
#define stdin PerlIO_stdin
#define stdout PerlIO_stdout
#define stderr PerlIO_stderr
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

#undef  THIS
#define THIS pPerl
#undef  THIS_
#define THIS_ pPerl,

#ifdef WIN32
#undef errno
#define errno				ErrorNo()
#undef  ErrorNo
#define ErrorNo				pPerl->ErrorNo
#undef  LastOLEError
#define LastOLEError		pPerl->Perl_LastOLEError
#undef  bOleInit
#define bOleInit			pPerl->Perl_bOleInit
#undef  CreatePerlOLEObject
#define CreatePerlOLEObject   pPerl->CreatePerlOLEObject
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

