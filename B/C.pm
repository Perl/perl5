#      C.pm
#
#      Copyright (c) 1996 Malcolm Beattie
#
#      You may distribute under the terms of either the GNU General Public
#      License or the Artistic License, as specified in the README file.
#
package B::C;
use Exporter ();
@ISA = qw(Exporter);
@EXPORT_OK = qw(push_decl init_init push_init output_all output_boilerplate
	       output_main set_callback save_unused_subs objsym);

use B qw(minus_c sv_undef walkoptree walksymtable main_root main_start
	 ad peekop class cstring cchar svref_2object compile_stats
	 comppadlist hash);
use B::Asmdata qw(@specialsv_name);

use FileHandle;
use Carp;
use strict;

my $hv_index = 0;
my $gv_index = 0;
my $re_index = 0;
my $pv_index = 0;
my $anonsub_index = 0;
my (@binop_list, @condop_list, @cop_list, @cvop_list, @decl_list,
    @gvop_list, @listop_list, @logop_list, @loop_list, @op_list, @pmop_list,
    @pvop_list, @sv_list, @svop_list, @unop_list, @xpv_list,
    @xpvav_list, @xpvhv_list, @xpvcv_list, @xpviv_list, @xpvnv_list, 
    @xpvmg_list, @xpvlv_list, @xrv_list, @xpvbm_list, @xpvio_list);

my $init_list_fh;
my %symtable;
my $warn_undefined_syms;
my $verbose;
my @unused_sub_packages;
my $nullop_count;
my $pv_copy_on_grow;
my ($debug_cops, $debug_av, $debug_cv, $debug_mg);

sub walk_and_save_optree;
my $saveoptree_callback = \&walk_and_save_optree;
sub set_callback { $saveoptree_callback = shift }
sub saveoptree { &$saveoptree_callback(@_) }

sub walk_and_save_optree {
    my ($name, $root, $start) = @_;
    walkoptree($root, "save");
    return objsym($start);
}

sub push_decl {
    push(@decl_list, @_);
}

sub init_init {
    $init_list_fh->close if defined $init_list_fh;
    $init_list_fh = FileHandle->new_tmpfile;
    return $init_list_fh ? 1 : 0;
}

sub push_init {
    map { print $init_list_fh $_, "\n" } @_;
}

# Current workaround/fix for op_free() trying to free statically
# defined OPs is to set op_seq = -1 and check for that in op_free().
# Instead of hardwiring -1 in place of $op->seq, we use $op_seq
# so that it can be changed back easily if necessary. In fact, to
# stop compilers from moaning about a U16 being initialised with an
# uncast -1 (the printf format is %d so we can't tweak it), we have
# to "know" that op_seq is a U16 and use 65535. Ugh.
my $op_seq = 65535;

sub AVf_REAL () { 1 }

sub savesym {
    my ($obj, $value) = @_;
#    warn(sprintf("savesym: sym_%x => %s\n", ad($obj), $value)); # debug
    $symtable{sprintf("sym_%x", ad($obj))} = $value;
}

sub objsym {
    my $obj = shift;
    return $symtable{sprintf("sym_%x", ad($obj))};
}

sub getsym {
    my $sym = shift;
    my $value;

    return 0 if $sym eq "sym_0";	# special case
    $value = $symtable{$sym};
    if (defined($value)) {
	return $value;
    } else {
	warn "warning: undefined symbol $sym\n" if $warn_undefined_syms;
	return "UNUSED";
    }
}

sub fixsyms {
    $_[0] =~ s/(sym_[0-9a-f]+)/getsym($1)/ge;
}

sub savepv {
    my $pv = shift;
    my $pvsym = 0;
    my $pvmax = 0;
    if ($pv_copy_on_grow) {
	my $cstring = cstring($pv);
	if ($cstring ne "0") { # sic
	    $pvsym = sprintf("pv%d", $pv_index++);
	    push(@decl_list,sprintf("static char %s[] = %s;",$pvsym,$cstring));
	}
    } else {
	$pvmax = length($pv) + 1;
    }
    return ($pvsym, $pvmax);
}

sub B::OP::save {
    my ($op, $level) = @_;
    my $type = $op->type;
    $nullop_count++ unless $type;
    push(@op_list,
	 sprintf("sym_%x, sym_%x, %s, %u, %u, %u, 0x%x, 0x%x",
		 ad($op->next), ad($op->sibling), $op->ppaddr, $op->targ,
		 $type, $op_seq, $op->flags, $op->private));
    savesym($op, "&op_list[$#op_list]");
}

sub B::FAKEOP::new {
    my ($class, %objdata) = @_;
    bless \%objdata, $class;
}

sub B::FAKEOP::save {
    my ($op, $level) = @_;
    push(@op_list,
	 sprintf("%s, %s, %s, %u, %u, %u, 0x%x, 0x%x",
		 $op->next, $op->sibling, $op->ppaddr, $op->targ,
		 $op->type, $op_seq, $op->flags, $op->private));
    return "&op_list[$#op_list]";
}

sub B::FAKEOP::next { $_[0]->{"next"} || 0 }
sub B::FAKEOP::type { $_[0]->{type} || 0}
sub B::FAKEOP::sibling { $_[0]->{sibling} || 0 }
sub B::FAKEOP::ppaddr { $_[0]->{ppaddr} || 0 }
sub B::FAKEOP::targ { $_[0]->{targ} || 0 }
sub B::FAKEOP::flags { $_[0]->{flags} || 0 }
sub B::FAKEOP::private { $_[0]->{private} || 0 }

sub B::UNOP::save {
    my ($op, $level) = @_;
    push(@unop_list,
	 sprintf("sym_%x, sym_%x, %s, %u, %u, %u, 0x%x, 0x%x, sym_%x",
		 ad($op->next), ad($op->sibling), $op->ppaddr, $op->targ,
		 $op->type, $op_seq, $op->flags,$op->private,ad($op->first)));
    savesym($op, "(OP*)&unop_list[$#unop_list]");
}

sub B::BINOP::save {
    my ($op, $level) = @_;
    push(@binop_list,
	 sprintf("sym_%x, sym_%x, %s, %u, %u, %u, 0x%x, 0x%x, sym_%x, sym_%x",
		 ad($op->next), ad($op->sibling), $op->ppaddr, $op->targ,
		 $op->type, $op_seq, $op->flags, $op->private,
		 ad($op->first), ad($op->last)));
    savesym($op, "(OP*)&binop_list[$#binop_list]");
}

sub B::LISTOP::save {
    my ($op, $level) = @_;
    push(@listop_list, sprintf(
	"sym_%x, sym_%x, %s, %u, %u, %u, 0x%x, 0x%x, sym_%x, sym_%x, %u",
	ad($op->next), ad($op->sibling), $op->ppaddr, $op->targ,
	$op->type, $op_seq, $op->flags, $op->private, ad($op->first),
	ad($op->last), $op->children));
    savesym($op, "(OP*)&listop_list[$#listop_list]");
}

sub B::LOGOP::save {
    my ($op, $level) = @_;
    push(@logop_list,
	 sprintf("sym_%x, sym_%x, %s, %u, %u, %u, 0x%x, 0x%x, sym_%x, sym_%x",
		 ad($op->next), ad($op->sibling), $op->ppaddr, $op->targ,
		 $op->type, $op_seq, $op->flags, $op->private,
		 ad($op->first), ad($op->other)));
    savesym($op, "(OP*)&logop_list[$#logop_list]");
}

sub B::CONDOP::save {
    my ($op, $level) = @_;
    push(@condop_list, sprintf(
	"sym_%x, sym_%x, %s, %u, %u, %u, 0x%x, 0x%x, sym_%x, sym_%x, sym_%x",
	ad($op->next), ad($op->sibling), $op->ppaddr, $op->targ,
	$op->type, $op_seq, $op->flags, $op->private, ad($op->first),
	ad($op->true), ad($op->false)));
    savesym($op, "(OP*)&condop_list[$#condop_list]");
}

sub B::LOOP::save {
    my ($op, $level) = @_;
    #warn sprintf("LOOP: redoop %s, nextop %s, lastop %s\n",
    #		 peekop($op->redoop), peekop($op->nextop),
    #		 peekop($op->lastop)); # debug
    push(@loop_list, sprintf(
	"sym_%x, sym_%x, %s, %u, %u, %u, 0x%x, 0x%x, "
	."sym_%x, sym_%x, %u, sym_%x, sym_%x, sym_%x",
	ad($op->next), ad($op->sibling), $op->ppaddr, $op->targ, $op->type,
	$op_seq, $op->flags, $op->private, ad($op->first), ad($op->last),
	$op->children, ad($op->redoop), ad($op->nextop), ad($op->lastop)));
    savesym($op, "(OP*)&loop_list[$#loop_list]");
}

sub B::PVOP::save {
    my ($op, $level) = @_;
    push(@pvop_list,
	 sprintf("sym_%x, sym_%x, %s, %u, %u, %u, 0x%x, 0x%x, %s",
		 ad($op->next), ad($op->sibling), $op->ppaddr, $op->targ,
		 $op->type, $op_seq, $op->flags, $op->private,
		 cstring($op->pv)));
    savesym($op, "(OP*)&pvop_list[$#pvop_list]");
}

sub B::SVOP::save {
    my ($op, $level) = @_;
    push(@svop_list,
	 sprintf("sym_%x, sym_%x, %s, %u, %u, %u, 0x%x, 0x%x, (SV*)sym_%x",
		 ad($op->next), ad($op->sibling), $op->ppaddr, $op->targ,
		 $op->type, $op_seq, $op->flags, $op->private, ad($op->sv)));
    savesym($op, "(OP*)&svop_list[$#svop_list]");
#    warn sprintf("svop saving sv %s 0x%x\n", ref($op->sv), ad($op->sv));#debug
    $op->sv->save;
}

sub B::GVOP::save {
    my ($op, $level) = @_;
    my $gvsym = $op->gv->save;
    push(@gvop_list,
	 sprintf("sym_%x, sym_%x, %s, %u, %u, %u, 0x%x, 0x%x, Nullgv",
		 ad($op->next), ad($op->sibling), $op->ppaddr, $op->targ,
		 $op->type, $op_seq, $op->flags, $op->private));
    push_init(sprintf("gvop_list[$#gvop_list].op_gv = %s;", $gvsym));
    savesym($op, "(OP*)&gvop_list[$#gvop_list]");
}

sub B::COP::save {
    my ($op, $level) = @_;
    my $gvsym = $op->filegv->save;
    my $stashsym = $op->stash->save;
    warn sprintf("COP: line %d file %s\n", $op->line, $op->filegv->SV->PV)
	if $debug_cops;
    push(@cop_list,
	 sprintf("sym_%x, sym_%x, %s, %u, %u, %u, 0x%x, 0x%x, %s, "
		 ."Nullhv, Nullgv, %u, %d, %u",
		 ad($op->next), ad($op->sibling), $op->ppaddr, $op->targ,
		 $op->type, $op_seq, $op->flags, $op->private,
		 cstring($op->label), $op->cop_seq, $op->arybase, $op->line));
    push_init(sprintf("cop_list[$#cop_list].cop_filegv = %s;", $gvsym),
	      sprintf("cop_list[$#cop_list].cop_stash = %s;", $stashsym));
    savesym($op, "(OP*)&cop_list[$#cop_list]");
}

sub B::PMOP::save {
    my ($op, $level) = @_;
    my $shortsym = $op->pmshort->save;
    my $replroot = $op->pmreplroot;
    my $replstart = $op->pmreplstart;
    my $replrootfield = sprintf("sym_%x", ad($replroot));
    my $replstartfield = sprintf("sym_%x", ad($replstart));
    my $gvsym;
    my $ppaddr = $op->ppaddr;
    if (ad($replroot)) {
	# OP_PUSHRE (a mutated version of OP_MATCH for the regexp
	# argument to a split) stores a GV in op_pmreplroot instead
	# of a substitution syntax tree. We don't want to walk that...
	if ($ppaddr eq "pp_pushre") {
	    $gvsym = $replroot->save;
#	    warn "PMOP::save saving a pp_pushre with GV $gvsym\n"; # debug
	    $replrootfield = 0;
	} else {
	    $replstartfield = saveoptree("*ignore*", $replroot, $replstart);
	}
    }
    # pmnext handling is broken in perl itself, I think. Bad op_pmnext
    # fields aren't noticed in perl's runtime (unless you try reset) but we
    # segfault when trying to dereference it to find op->op_pmnext->op_type
    push(@pmop_list,
	 sprintf("sym_%x, sym_%x, %s, %u, %u, %u, 0x%x, 0x%x, sym_%x, sym_%x,"
		 ." %u, %s, %s, 0, 0, %s, 0x%x, 0x%x, %u",
		 ad($op->next), ad($op->sibling), $ppaddr, $op->targ,
		 $op->type, $op_seq, $op->flags, $op->private,
		 ad($op->first), ad($op->last), $op->children,
		 $replrootfield, $replstartfield,
		 $shortsym, $op->pmflags, $op->pmpermflags, $op->pmslen));
    my $pm = "pmop_list[$#pmop_list]";
    my $re = $op->precomp;
    if (defined($re)) {
	my $resym = sprintf("re%d", $re_index++);
	push(@decl_list, sprintf("static char *$resym = %s;", cstring($re)));
	push_init(sprintf(
	    "$pm.op_pmregexp = pregcomp($resym, $resym + %u, &$pm);",
	    length($re)));
    }
    if ($gvsym) {
	push_init("$pm.op_pmreplroot = (OP*)$gvsym;");
    }
    savesym($op, "(OP*)&pmop_list[$#pmop_list]");
}

sub B::SPECIAL::save {
    my ($sv) = @_;
    # special case: $$sv is not the address but an index into specialsv_list
#   warn "SPECIAL::save specialsv $$sv\n"; # debug
    my $sym = $specialsv_name[$$sv];
    if (!defined($sym)) {
	confess "unknown specialsv index $$sv passed to B::SPECIAL::save";
    }
    return $sym;
}

sub B::OBJECT::save {}

sub B::NULL::save {
    my ($sv) = @_;
    my $sym = objsym($sv);
    return $sym if defined $sym;
#   warn "Saving SVt_NULL SV\n"; # debug
    # debug
    #if ($$sv == 0) {
    #	warn "NULL::save for sv = 0 called from @{[(caller(1))[3]]}\n";
    #}
    push(@sv_list, sprintf("0, %u, 0x%x", $sv->REFCNT + 1, $sv->FLAGS));
    return savesym($sv, "&sv_list[$#sv_list]");
}

sub B::IV::save {
    my ($sv) = @_;
    my $sym = objsym($sv);
    return $sym if defined $sym;
    push(@xpviv_list, sprintf("0, 0, 0, %d", $sv->IVX));
    push(@sv_list, sprintf("&xpviv_list[$#xpviv_list], %lu, 0x%x",
			   $sv->REFCNT + 1, $sv->FLAGS));
    return savesym($sv, "&sv_list[$#sv_list]");
}

sub B::NV::save {
    my ($sv) = @_;
    my $sym = objsym($sv);
    return $sym if defined $sym;
    push(@xpvnv_list, sprintf("0, 0, 0, %d, %s", $sv->IVX, $sv->NVX));
    push(@sv_list, sprintf("&xpvnv_list[$#xpvnv_list], %lu, 0x%x",
			   $sv->REFCNT + 1, $sv->FLAGS));
    return savesym($sv, "&sv_list[$#sv_list]");
}

sub B::PVLV::save {
    my ($sv) = @_;
    my $sym = objsym($sv);
    return $sym if defined $sym;
    my $pv = $sv->PV;
    my $len = length($pv);
    my ($pvsym, $pvmax) = savepv($pv);
    my ($lvtarg, $lvtarg_sym);
    push(@xpvlv_list, sprintf("%s, %u, %u, %d, %g, 0, 0, %u, %u, 0, %s",
			      $pvsym, $len, $pvmax, $sv->IVX, $sv->NVX, 
			      $sv->TARGOFF, $sv->TARGLEN, cchar($sv->TYPE)));
      
    push(@sv_list, sprintf("&xpvlv_list[$#xpvlv_list], %lu, 0x%x",
			   $sv->REFCNT + 1, $sv->FLAGS));
    if (!$pv_copy_on_grow) {
	push_init(sprintf("xpvlv_list[$#xpvlv_list].xpv_pv = savepvn(%s, %u);",
			  cstring($pv), $len));
    }
    $sv->save_magic;
    return savesym($sv, "&sv_list[$#sv_list]");
}

sub B::PVIV::save {
    my ($sv) = @_;
    my $sym = objsym($sv);
    return $sym if defined $sym;
    my $pv = $sv->PV;
    my $len = length($pv);
    my ($pvsym, $pvmax) = savepv($pv);
    push(@xpviv_list, sprintf("%s, %u, %u, %d", $pvsym, $len,$pvmax,$sv->IVX));
    push(@sv_list, sprintf("&xpviv_list[$#xpviv_list], %u, 0x%x",
			   $sv->REFCNT + 1, $sv->FLAGS));
    if (!$pv_copy_on_grow) {
	push_init(sprintf("xpviv_list[$#xpviv_list].xpv_pv = savepvn(%s, %u);",
			  cstring($pv), $len));
    }
    return savesym($sv, "&sv_list[$#sv_list]");
}

sub B::PVNV::save {
    my ($sv) = @_;
    my $sym = objsym($sv);
    return $sym if defined $sym;
    my $pv = $sv->PV;
    my $len = length($pv);
    my ($pvsym, $pvmax) = savepv($pv);
    push(@xpvnv_list, sprintf("%s, %u, %u, %d, %s",
			      $pvsym, $len, $pvmax, $sv->IVX, $sv->NVX));
    push(@sv_list, sprintf("&xpvnv_list[$#xpvnv_list], %lu, 0x%x",
			   $sv->REFCNT + 1, $sv->FLAGS));
    if (!$pv_copy_on_grow) {
	push_init(sprintf("xpvnv_list[$#xpvnv_list].xpv_pv = savepvn(%s, %u);",
			  cstring($pv), $len));
    }
    return savesym($sv, "&sv_list[$#sv_list]");
}

sub B::BM::save {
    my ($sv) = @_;
    my $sym = objsym($sv);
    return $sym if defined $sym;
    my $pv = $sv->PV . "\0" . $sv->TABLE;
    my $len = length($pv);
    push(@xpvbm_list, sprintf("0, %u, %u, %d, %s, 0, 0, %d, %u, 0x%x",
			      $len, $len + 258, $sv->IVX, $sv->NVX,
			      $sv->USEFUL, $sv->PREVIOUS, $sv->RARE));
    push(@sv_list, sprintf("&xpvbm_list[$#xpvbm_list], %lu, 0x%x",
			   $sv->REFCNT + 1, $sv->FLAGS));
    $sv->save_magic;
    push_init(sprintf("xpvbm_list[$#xpvbm_list].xpv_pv = savepvn(%s, %u);",
		      cstring($pv), $len),
	      sprintf("xpvbm_list[$#xpvbm_list].xpv_cur = %u;", $len - 257));
#	      "sv_magic(&sv_list[$#sv_list], Nullsv, 'B', Nullch, 0);");
    return savesym($sv, "&sv_list[$#sv_list]");
}

sub B::PV::save {
    my ($sv) = @_;
    my $sym = objsym($sv);
    return $sym if defined $sym;
    my $pv = $sv->PV;
    my $len = length($pv);
    my ($pvsym, $pvmax) = savepv($pv);
    push(@xpv_list, sprintf("%s, %u, %u", $pvsym, $len, $pvmax));
    push(@sv_list, sprintf("&xpv_list[$#xpv_list], %lu, 0x%x",
			   $sv->REFCNT + 1, $sv->FLAGS));
    if (!$pv_copy_on_grow) {
	push_init(sprintf("xpv_list[$#xpv_list].xpv_pv = savepvn(%s, %u);",
			  cstring($pv), $len));
    }
    return savesym($sv, "&sv_list[$#sv_list]");
}

sub B::PVMG::save {
    my ($sv) = @_;
    my $sym = objsym($sv);
    return $sym if defined $sym;
    my $pv = $sv->PV;
    my $len = length($pv);
    my ($pvsym, $pvmax) = savepv($pv);
    push(@xpvmg_list, sprintf("%s, %u, %u, %d, %s, 0, 0",
			      $pvsym, $len, $pvmax, $sv->IVX, $sv->NVX));
    push(@sv_list, sprintf("&xpvmg_list[$#xpvmg_list], %lu, 0x%x",
			   $sv->REFCNT + 1, $sv->FLAGS));
    if (!$pv_copy_on_grow) {
	push_init(sprintf("xpvmg_list[$#xpvmg_list].xpv_pv = savepvn(%s, %u);",
			  cstring($pv), $len));
    }
    $sym = savesym($sv, "&sv_list[$#sv_list]");
    $sv->save_magic;
    return $sym;
}

sub B::PVMG::save_magic {
    my ($sv) = @_;
    #warn sprintf("saving magic for %s (0x%x)\n", class($sv), ad($sv)); # debug
    my $stash = $sv->SvSTASH;
    if (ad($stash)) {
	warn sprintf("xmg_stash = %s (0x%x)\n", $stash->NAME, ad($stash))
	    if $debug_mg;
	# XXX Hope stash is already going to be saved.
	push_init(sprintf("SvSTASH(sym_%x) = sym_%x;", ad($sv), ad($stash)));
    }
    my @mgchain = $sv->MAGIC;
    my ($mg, $type, $obj, $ptr);
    foreach $mg (@mgchain) {
	$type = $mg->TYPE;
	$obj = $mg->OBJ;
	$ptr = $mg->PTR;
	my $len = defined($ptr) ? length($ptr) : 0;
	if ($debug_mg) {
	    warn sprintf("magic %s (0x%x), obj %s (0x%x), type %s, ptr %s\n",
			 class($sv), ad($sv), class($obj), ad($obj),
			 cchar($type), cstring($ptr));
	}
	push_init(sprintf("sv_magic((SV*)sym_%x, (SV*)sym_%x, %s, %s, %d);",
			  ad($sv), ad($obj), cchar($type),cstring($ptr),$len));
    }
}

sub B::RV::save {
    my ($sv) = @_;
    my $sym = objsym($sv);
    return $sym if defined $sym;
    push(@xrv_list, $sv->RV->save);
    push(@sv_list, sprintf("&xrv_list[$#xrv_list], %lu, 0x%x",
			   $sv->REFCNT + 1, $sv->FLAGS));
    return savesym($sv, "&sv_list[$#sv_list]");
}

sub B::CV::save {
    my ($cv) = @_;
    my $sym = objsym($cv);
    if (defined($sym)) {
#	warn sprintf("CV 0x%x already saved as $sym\n", ad($cv)); # debug
	return $sym;
    }
    # Reserve a place on sv_list and xpvcv_list and record indices
    push(@sv_list, undef);
    my $sv_ix = $#sv_list;
    push(@xpvcv_list, undef);
    my $xpvcv_ix = $#xpvcv_list;
    # Save symbol now so that GvCV() doesn't recurse back to us via CvGV()
    $sym = savesym($cv, "&sv_list[$sv_ix]");
    warn sprintf("saving CV 0x%x as $sym\n", ad($cv)) if $debug_cv;
    my $gv = $cv->GV;
    my $root = $cv->ROOT;
    my $startfield = 0;
    my $padlist = $cv->PADLIST;
    if (ad($root)) {
	warn sprintf("saving op tree for CV 0x%x, root = 0x%x\n",
		     ad($cv), ad($root)) if $debug_cv;
	my $ppname;
	if (ad($gv)) {
	    my $stashname = $gv->STASH->NAME;
	    my $gvname = $gv->NAME;
	    $ppname = "pp_sub_";
	    $ppname .= $stashname eq "main" ? $gvname : "$stashname\::$gvname";
	    $ppname =~ s/::/__/g;
	} else {
	    $ppname = "pp_anonsub_$anonsub_index";
	    $anonsub_index++;
	}
	$startfield = saveoptree($ppname, $root, $cv->START, $padlist->ARRAY);
	warn sprintf("done saving op tree for CV 0x%x, name %s, root 0x%x\n",
		     ad($cv), $ppname, ad($root)) if $debug_cv;
    }
    if (ad($padlist)) {
	warn sprintf("saving PADLIST 0x%x for CV 0x%x\n",
		     ad($padlist), ad($cv)) if $debug_cv;
	$padlist->save;
	warn sprintf("done saving PADLIST 0x%x for CV 0x%x\n",
		     ad($padlist), ad($cv)) if $debug_cv;
    }
    my $pv = $cv->PV;
    my $xsub = 0;
    my $xsubany = "Nullany";
    if ($cv->XSUB) {
	$xsubany = sprintf("ANYINIT((void*)0x%x)", $cv->XSUBANY);
	# Find out canonical name of XSUB function from EGV (I hope)
	my $egv = $gv->EGV;
	my $stashname = $egv->STASH->NAME;
	$stashname =~ s/::/__/g;
	$xsub = sprintf("XS_%s_%s", $stashname, $egv->NAME);
	push(@decl_list, "void $xsub _((CV*));");
    }
    $xpvcv_list[$xpvcv_ix] = sprintf(
	"%s, %u, 0, %d, %s, 0, Nullhv, Nullhv, %s, sym_%lx, $xsub, $xsubany,".
	" Nullgv, Nullgv, %d, sym_%lx, (CV*)sym_%lx, 0",
	cstring($pv), length($pv), $cv->IVX, $cv->NVX, $startfield,
	ad($cv->ROOT), $cv->DEPTH, ad($padlist), ad($cv->OUTSIDE));
    if (ad($gv)) {
	$gv->save;
	push_init(sprintf("CvGV(sym_%lx) = sym_%lx;",ad($cv),ad($gv)));
	warn sprintf("done saving GV 0x%x for CV 0x%x\n",
		     ad($gv), ad($cv)) if $debug_cv;
    }
    my $filegv = $cv->FILEGV;
    if (ad($filegv)) {
	$filegv->save;
	push_init(sprintf("CvFILEGV(sym_%lx) = sym_%lx;",ad($cv),ad($filegv)));
	warn sprintf("done saving FILEGV 0x%x for CV 0x%x\n",
		     ad($filegv), ad($cv)) if $debug_cv;
    }
    my $stash = $cv->STASH;
    if (ad($stash)) {
	$stash->save;
	push_init(sprintf("CvSTASH(sym_%lx) = sym_%lx;", ad($cv), ad($stash)));
	warn sprintf("done saving STASH 0x%x for CV 0x%x\n",
		     ad($stash), ad($cv)) if $debug_cv;
    }
    $sv_list[$sv_ix] = sprintf("(XPVCV*)&xpvcv_list[%u], %lu, 0x%x",
			       $xpvcv_ix, $cv->REFCNT + 1, $cv->FLAGS);
    return $sym;
}

sub B::GV::save {
    my ($gv) = @_;
    my $sym = objsym($gv);
    if (defined($sym)) {
	#warn sprintf("GV 0x%x already saved as $sym\n", ad($gv)); # debug
	return $sym;
    } else {
	my $ix = $gv_index++;
	$sym = savesym($gv, "gv_list[$ix]");
	#warn sprintf("Saving GV 0x%x as $sym\n", ad($gv)); # debug
    }
    my $gvname = $gv->NAME;
    my $name = cstring($gv->STASH->NAME . "::" . $gvname);
    #warn "GV name is $name\n"; # debug
    my $egv = $gv->EGV;
    my $egvsym;
    if (ad($gv) != ad($egv)) {
	#warn(sprintf("EGV name is %s, saving it now\n",
	#	     $egv->STASH->NAME . "::" . $egv->NAME)); # debug
	$egvsym = $egv->save;
    }
    push_init(qq[$sym = gv_fetchpv($name, TRUE, SVt_PV);],
	      sprintf("SvFLAGS($sym) = 0x%x;", $gv->FLAGS),
	      sprintf("GvFLAGS($sym) = 0x%x;", $gv->GvFLAGS),
	      sprintf("GvLINE($sym) = %u;", $gv->LINE));
    # Shouldn't need to do save_magic since gv_fetchpv handles that
    #$gv->save_magic;
    my $refcnt = $gv->REFCNT + 1;
    push_init(sprintf("SvREFCNT($sym) += %u;", $refcnt - 1)) if $refcnt > 1;
    my $gvrefcnt = $gv->GvREFCNT;
    if ($gvrefcnt > 1) {
	push_init(sprintf("GvREFCNT($sym) += %u;", $gvrefcnt - 1));
    }
    if (defined($egvsym)) {
	# Shared glob *foo = *bar
	push_init("gp_free($sym);",
		  "GvGP($sym) = GvGP($egvsym);");
    } elsif ($gvname !~ /^([^A-Za-z]|STDIN|STDOUT|STDERR|ARGV|SIG|ENV)$/) {
	# Don't save subfields of special GVs (*_, *1, *# and so on)
#	warn "GV::save saving subfields\n"; # debug
	my $gvsv = $gv->SV;
	if (ad($gvsv)) {
	    push_init(sprintf("GvSV($sym) = sym_%x;", ad($gvsv)));
#	    warn "GV::save \$$name\n"; # debug
	    $gvsv->save;
	}
	my $gvav = $gv->AV;
	if (ad($gvav)) {
	    push_init(sprintf("GvAV($sym) = sym_%x;", ad($gvav)));
#	    warn "GV::save \@$name\n"; # debug
	    $gvav->save;
	}
	my $gvhv = $gv->HV;
	if (ad($gvhv)) {
	    push_init(sprintf("GvHV($sym) = sym_%x;", ad($gvhv)));
#	    warn "GV::save \%$name\n"; # debug
	    $gvhv->save;
	}
	my $gvcv = $gv->CV;
	if (ad($gvcv)) {
	    push_init(sprintf("GvCV($sym) = (CV*)sym_%x;", ad($gvcv)));
#	    warn "GV::save &$name\n"; # debug
	    $gvcv->save;
	}
	my $gvfilegv = $gv->FILEGV;
	if (ad($gvfilegv)) {
	    push_init(sprintf("GvFILEGV($sym) = sym_%x;",ad($gvfilegv)));
#	    warn "GV::save GvFILEGV(*$name)\n"; # debug
	    $gvfilegv->save;
	}
	my $gvform = $gv->FORM;
	if (ad($gvform)) {
	    push_init(sprintf("GvFORM($sym) = (CV*)sym_%x;", ad($gvform)));
#	    warn "GV::save GvFORM(*$name)\n"; # debug
	    $gvform->save;
	}
	my $gvio = $gv->IO;
	if (ad($gvio)) {
	    push_init(sprintf("GvIOp($sym) = sym_%x;", ad($gvio)));
#	    warn "GV::save GvIO(*$name)\n"; # debug
	    $gvio->save;
	}
    }
    return $sym;
}
sub B::AV::save {
    my ($av) = @_;
    my $sym = objsym($av);
    return $sym if defined $sym;
    my $avflags = $av->AvFLAGS;
    push(@xpvav_list,
	 sprintf("0, -1, -1, 0, 0.0, 0, Nullhv, 0, 0, 0x%x", $avflags));
    push(@sv_list, sprintf("&xpvav_list[$#xpvav_list], %lu, 0x%x",
			   $av->REFCNT + 1, $av->FLAGS));
    my $sv_list_index = $#sv_list;
    my $fill = $av->FILL;
    $av->save_magic;
    warn sprintf("saving AV 0x%x FILL=$fill AvFLAGS=0x%x", ad($av), $avflags)
	if $debug_av;
    # XXX AVf_REAL is wrong test: need to save comppadlist but not stack
    #if ($fill > -1 && ($avflags & AVf_REAL)) {
    if ($fill > -1) {
	my @array = $av->ARRAY;
	if ($debug_av) {
	    my $el;
	    my $i = 0;
	    foreach $el (@array) {
		warn sprintf("AV 0x%x[%d] = %s 0x%x\n",
			     ad($av), $i++, class($el), ad($el));
	    }
	}
	my @names = map($_->save, @array);
	# XXX Better ways to write loop?
	# Perhaps svp[0] = ...; svp[1] = ...; svp[2] = ...;
	# Perhaps I32 i = 0; svp[i++] = ...; svp[i++] = ...; svp[i++] = ...;
	push_init("{",
		  "\tSV **svp;",
		  "\tAV *av = (AV*)&sv_list[$sv_list_index];",
		  "\tav_extend(av, $fill);",
		  "\tsvp = AvARRAY(av);",
	      map("\t*svp++ = (SV*)$_;", @names),
		  "\tAvFILL(av) = $fill;",
		  "}");
    } else {
	my $max = $av->MAX;
	push_init("av_extend((AV*)&sv_list[$sv_list_index], $max);")
	    if $max > -1;
    }
    return savesym($av, "(AV*)&sv_list[$sv_list_index]");
}

sub B::HV::save {
    my ($hv) = @_;
    my $sym = objsym($hv);
    return $sym if defined $sym;
    my $name = $hv->NAME;
    if ($name) {
	# It's a stash

	# A perl bug means HvPMROOT isn't altered when a PMOP is freed. Usually
	# the only symptom is that sv_reset tries to reset the PMf_USED flag of
	# a trashed op but we look at the trashed op_type and segfault.
	#my $adpmroot = ad($hv->PMROOT);
	my $adpmroot = 0;
	push(@decl_list, "static HV *hv$hv_index;");
	# XXX Beware of weird package names containing double-quotes, \n, ...?
	push_init(qq[hv$hv_index = gv_stashpv("$name", TRUE);]);
	if ($adpmroot) {
	    push_init(sprintf("HvPMROOT(hv$hv_index) = (PMOP*)sym_%x;",
			      $adpmroot));
	}
	$sym = savesym($hv, "hv$hv_index");
	$hv_index++;
	return $sym;
    }
    # It's just an ordinary HV
    push(@xpvhv_list,
	 sprintf("0, 0, %d, 0, 0.0, 0, Nullhv, %d, 0, 0, 0",
		 $hv->MAX, $hv->RITER));
    push(@sv_list, sprintf("&xpvhv_list[$#xpvhv_list], %lu, 0x%x",
			   $hv->REFCNT + 1, $hv->FLAGS));
    my $sv_list_index = $#sv_list;
    my @contents = $hv->ARRAY;
    if (@contents) {
	my $i;
	for ($i = 1; $i < @contents; $i += 2) {
	    $contents[$i] = $contents[$i]->save;
	}
	push_init("{", "\tHV *hv = (HV*)&sv_list[$sv_list_index];");
	while (@contents) {
	    my ($key, $value) = splice(@contents, 0, 2);
	    push_init(sprintf("\thv_store(hv, %s, %u, %s, %s);",
			      cstring($key),length($key), $value, hash($key)));
	}
	push_init("}");
    }
    return savesym($hv, "(HV*)&sv_list[$sv_list_index]");
}

sub B::IO::save {
    my ($io) = @_;
    my $sym = objsym($io);
    return $sym if defined $sym;
    my $pv = $io->PV;
    my $len = length($pv);
    push(@xpvio_list,
	 sprintf("0, %u, %u, %d, %s, 0, 0, 0, 0, 0, %d, %d, %d, %d, %s, "
		 ."Nullgv, %s, Nullgv, %s, Nullgv, %d, %s, 0x%x",
		 $len, $len+1, $io->IVX, $io->NVX,
		 $io->LINES, $io->PAGE, $io->PAGE_LEN, $io->LINES_LEFT, 
		 cstring($io->TOP_NAME), cstring($io->FMT_NAME), 
		 cstring($io->BOTTOM_NAME), $io->SUBPROCESS,
		 cchar($io->IoTYPE), $io->IoFLAGS));
    push(@sv_list, sprintf("&xpvio_list[$#xpvio_list], %lu, 0x%x",
			   $io->REFCNT + 1, $io->FLAGS));
    $sym = savesym($io, "(IO*)&sv_list[$#sv_list]");
    my ($field, $fsym);
    foreach $field (qw(TOP_GV FMT_GV BOTTOM_GV)) {
      	$fsym = $io->$field();
	if (ad($fsym)) {
	    push_init(sprintf("Io$field($sym) = (GV*)sym_%x;", ad($fsym)));
	    $fsym->save;
	}
    }
    $io->save_magic;
    return $sym;
}

sub B::SV::save {
    my $sv = shift;
    # This is where we catch an honest-to-goodness Nullsv (which gets
    # blessed into B::SV explicitly) and any stray erroneous SVs.
    return 0 unless ad($sv);
    confess sprintf("cannot save that type of SV: %s (0x%x)\n",
		    class($sv), ad($sv));
}

sub output_all {
    my $init_name = shift;

    output_declarations();
    print "$_\n" while $_ = shift @decl_list;
    print "\n";
    output_list("op", \@op_list) if @op_list;
    output_list("unop", \@unop_list) if @unop_list;
    output_list("binop", \@binop_list) if @binop_list;
    output_list("logop", \@logop_list) if @logop_list;
    output_list("condop", \@condop_list) if @condop_list;
    output_list("listop", \@listop_list) if @listop_list;
    output_list("pmop", \@pmop_list) if @pmop_list;
    output_list("svop", \@svop_list) if @svop_list;
    output_list("gvop", \@gvop_list) if @gvop_list;
    output_list("pvop", \@pvop_list) if @pvop_list;
    output_list("cvop", \@cvop_list) if @cvop_list;
    output_list("loop", \@loop_list) if @loop_list;
    output_list("cop", \@cop_list) if @cop_list;

    output_list("sv", \@sv_list) if @sv_list;
    output_list("xrv", \@xrv_list) if @xrv_list;
    output_list("xpv", \@xpv_list) if @xpv_list;
    output_list("xpviv", \@xpviv_list) if @xpviv_list;
    output_list("xpvnv", \@xpvnv_list) if @xpvnv_list;
    output_list("xpvmg", \@xpvmg_list) if @xpvmg_list;
    output_list("xpvlv", \@xpvlv_list) if @xpvlv_list;
    output_list("xpvbm", \@xpvbm_list) if @xpvbm_list;
    output_list("xpvav", \@xpvav_list) if @xpvav_list;
    output_list("xpvhv", \@xpvhv_list) if @xpvhv_list;
    output_list("xpvio", \@xpvio_list) if @xpvio_list;
    output_list("xpvcv", \@xpvcv_list) if @xpvcv_list;

    output_init($init_name);
    if ($verbose) {
	warn compile_stats();
	warn "NULLOP count: $nullop_count\n";
    }
}

sub output_init {
    my $name = shift;
    print "static int $name()\n{\n";
    seek($init_list_fh, 0, 0);
    while (<$init_list_fh>) {
	fixsyms($_);
	print "\t", $_;
    }
    print "\treturn 0;\n}\n";
}

sub output_list {
    my ($name, $listref) = @_;
    # Support pre-Standard C compilers which can't cope with static
    # initialisation of union members. Sheesh.
    my $typename = ($name eq "xpvcv") ? "XPVCV_or_similar" : uc($name);
    printf "static %s %s_list[%u] = {\n", $typename, $name, scalar(@$listref);
    while ($_ = shift @$listref) {
	fixsyms($_);
	print "\t{ $_ },\n";
    }
    print "};\n\n";
}

sub output_declarations {
    print <<'EOT';
#ifdef BROKEN_STATIC_REDECL
#define Static extern
#else
#define Static static
#endif /* BROKEN_STATIC_REDECL */

#ifdef BROKEN_UNION_INIT
/*
 * Cribbed from cv.h with ANY (a union) replaced by void*.
 * Some pre-Standard compilers can't cope with initialising unions. Ho hum.
 */
typedef struct {
    char *	xpv_pv;		/* pointer to malloced string */
    STRLEN	xpv_cur;	/* length of xp_pv as a C string */
    STRLEN	xpv_len;	/* allocated size */
    IV		xof_off;	/* integer value */
    double	xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* magic for scalar array */
    HV*		xmg_stash;	/* class package */

    HV *	xcv_stash;
    OP *	xcv_start;
    OP *	xcv_root;
    void      (*xcv_xsub) _((CV*));
    void *	xcv_xsubany;
    GV *	xcv_gv;
    GV *	xcv_filegv;
    long	xcv_depth;		/* >= 2 indicates recursive call */
    AV *	xcv_padlist;
    CV *	xcv_outside;
    U8		xcv_flags;
} XPVCV_or_similar;
#define ANYINIT(i) i
#else
#define XPVCV_or_similar XPVCV
#define ANYINIT(i) {i}
#endif /* BROKEN_UNION_INIT */
#define Nullany ANYINIT(0)

#define UNUSED 0

EOT
    printf("Static OP op_list[%d];\n", scalar(@op_list)) if @op_list;
    printf("Static UNOP unop_list[%d];\n", scalar(@unop_list)) if @unop_list;
    printf("Static BINOP binop_list[%d];\n", scalar(@binop_list))
	if @binop_list;
    printf("Static LOGOP logop_list[%d];\n", scalar(@logop_list))
	if @logop_list;
    printf("Static CONDOP condop_list[%d];\n", scalar(@condop_list))
	if @condop_list;
    printf("Static LISTOP listop_list[%d];\n", scalar(@listop_list))
	if @listop_list;
    printf("Static PMOP pmop_list[%d];\n", scalar(@pmop_list)) if @pmop_list;
    printf("Static SVOP svop_list[%d];\n", scalar(@svop_list)) if @svop_list;
    printf("Static GVOP gvop_list[%d];\n", scalar(@gvop_list)) if @gvop_list;
    printf("Static PVOP pvop_list[%d];\n", scalar(@pvop_list)) if @pvop_list;
    printf("Static CVOP cvop_list[%d];\n", scalar(@cvop_list)) if @cvop_list;
    printf("Static LOOP loop_list[%d];\n", scalar(@loop_list)) if @loop_list;
    printf("Static COP cop_list[%d];\n", scalar(@cop_list)) if @cop_list;

    printf("Static SV sv_list[%d];\n", scalar(@sv_list)) if @sv_list;
    printf("Static XPV xpv_list[%d];\n", scalar(@xpv_list)) if @xpv_list;
    printf("Static XRV xrv_list[%d];\n", scalar(@xrv_list)) if @xrv_list;
    printf("Static XPVIV xpviv_list[%d];\n", scalar(@xpviv_list))
	if @xpviv_list;
    printf("Static XPVNV xpvnv_list[%d];\n", scalar(@xpvnv_list))
	if @xpvnv_list;
    printf("Static XPVMG xpvmg_list[%d];\n", scalar(@xpvmg_list))
	if @xpvmg_list;
    printf("Static XPVLV xpvlv_list[%d];\n", scalar(@xpvlv_list))
	if @xpvlv_list;
    printf("Static XPVBM xpvbm_list[%d];\n", scalar(@xpvbm_list))
	if @xpvbm_list;
    printf("Static XPVAV xpvav_list[%d];\n", scalar(@xpvav_list))
	if @xpvav_list;
    printf("Static XPVHV xpvhv_list[%d];\n", scalar(@xpvhv_list))
	if @xpvhv_list;
    printf("Static XPVCV_or_similar xpvcv_list[%d];\n", scalar(@xpvcv_list))
	if @xpvcv_list;
    printf("Static XPVIO xpvio_list[%d];\n", scalar(@xpvio_list))
	if @xpvio_list;
    print "static GV *gv_list[$gv_index];\n" if $gv_index;
    print "\n";
}


sub output_boilerplate {
    print <<'EOT';
#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"

#ifdef __cplusplus
}
#  define EXTERN_C extern "C"
#else
#  define EXTERN_C extern
#endif

/* Workaround for mapstart: the only op which needs a different ppaddr */
#undef pp_mapstart
#define pp_mapstart pp_grepstart

static void xs_init _((void));
static PerlInterpreter *my_perl;
EOT
}

sub output_main {
    print <<'EOT';
int
#ifndef CAN_PROTOTYPE
main(argc, argv, env)
int argc;
char **argv;
char **env;
#else  /* def(CAN_PROTOTYPE) */
main(int argc, char **argv, char **env)
#endif  /* def(CAN_PROTOTYPE) */
{
    int exitstatus;
    int i;
    char **fakeargv;

    PERL_SYS_INIT(&argc,&argv);
 
#if PATCHLEVEL > 3 || (PATCHLEVEL == 3 && SUBVERSION >= 1)
    perl_init_i18nl10n(1);
#else
    perl_init_i18nl14n(1);
#endif

    if (!do_undump) {
	my_perl = perl_alloc();
	if (!my_perl)
	    exit(1);
	perl_construct( my_perl );
    }

    if (!cshlen) 
      cshlen = strlen(cshname);

#ifdef ALLOW_PERL_OPTIONS
#define EXTRA_OPTIONS 2
#else
#define EXTRA_OPTIONS 3
#endif /* ALLOW_PERL_OPTIONS */
    New(666, fakeargv, argc + EXTRA_OPTIONS + 1, char *);
    fakeargv[0] = argv[0];
    fakeargv[1] = "-e";
    fakeargv[2] = "";
#ifndef ALLOW_PERL_OPTIONS
    fakeargv[3] = "--";
#endif /* ALLOW_PERL_OPTIONS */
    for (i = 1; i < argc; i++)
	fakeargv[i + EXTRA_OPTIONS] = argv[i];
    fakeargv[argc + EXTRA_OPTIONS] = 0;
    
    exitstatus = perl_parse(my_perl, xs_init, argc + EXTRA_OPTIONS,
			    fakeargv, NULL);
    if (exitstatus)
	exit( exitstatus );

    sv_setpv(GvSV(gv_fetchpv("0", TRUE, SVt_PV)), argv[0]);
    main_cv = compcv;
    compcv = 0;

    exitstatus = perl_init();
    if (exitstatus)
	exit( exitstatus );

    exitstatus = perl_run( my_perl );

    perl_destruct( my_perl );
    perl_free( my_perl );

    exit( exitstatus );
}

static void
xs_init()
{
}
EOT
}

sub dump_symtable {
    # For debugging
    my ($sym, $val);
    warn "----Symbol table:\n";
    while (($sym, $val) = each %symtable) {
	warn "$sym => $val\n";
    }
    warn "---End of symbol table\n";
}

sub save_object {
    my $sv;
    foreach $sv (@_) {
	svref_2object($sv)->save;
    }
}

sub B::GV::savecv {
    my $gv = shift;
    my $cv = $gv->CV;
    my $name = $gv->NAME;
    if (ad($cv) && !objsym($cv) && !($name eq "bootstrap" && $cv->XSUB)) {
	if ($debug_cv) {
	    warn sprintf("saving extra CV &%s::%s (0x%x) from GV 0x%x\n",
			 $gv->STASH->NAME, $name, ad($cv), ad($gv));
	}
	$gv->save;
    }
}

sub save_unused_subs {
    my %search_pack;
    map { $search_pack{"$_\::"} = 1 } @_;
    no strict qw(vars refs);
    walksymtable(\%{"main::"}, "savecv", sub { exists($search_pack{$_[0]}) });
}

sub save_main {
    my $curpad_sym = (comppadlist->ARRAY)[1]->save;
    walkoptree(main_root, "save");
    if (@unused_sub_packages) {
	warn "done main optree, walking symtable for extras\n" if $debug_cv;
	save_unused_subs(@unused_sub_packages);
    }
    push_init(sprintf("main_root = sym_%x;", ad(main_root)),
	      sprintf("main_start = sym_%x;", ad(main_start)),
	      "curpad = AvARRAY($curpad_sym);");
    output_boilerplate();
    print "\n";
    output_all("perl_init");
    print "\n";
    output_main();
}

sub compile {
    my @options = @_;
    my ($option, $opt, $arg);
  OPTION:
    while ($option = shift @options) {
	if ($option =~ /^-(.)(.*)/) {
	    $opt = $1;
	    $arg = $2;
	} else {
	    unshift @options, $option;
	    last OPTION;
	}
	if ($opt eq "-" && $arg eq "-") {
	    shift @options;
	    last OPTION;
	}
	if ($opt eq "w") {
	    $warn_undefined_syms = 1;
	} elsif ($opt eq "D") {
	    $arg ||= shift @options;
	    foreach $arg (split(//, $arg)) {
		if ($arg eq "o") {
		    B->debug(1);
		} elsif ($arg eq "c") {
		    $debug_cops = 1;
		} elsif ($arg eq "A") {
		    $debug_av = 1;
		} elsif ($arg eq "C") {
		    $debug_cv = 1;
		} elsif ($arg eq "M") {
		    $debug_mg = 1;
		} else {
		    warn "ignoring unknown debug option: $arg\n";
		}
	    }
	} elsif ($opt eq "o") {
	    $arg ||= shift @options;
	    open(STDOUT, ">$arg") or return "$arg: $!\n";
	} elsif ($opt eq "v") {
	    $verbose = 1;
	} elsif ($opt eq "u") {
	    $arg ||= shift @options;
	    push(@unused_sub_packages, $arg);
	} elsif ($opt eq "f") {
	    $arg ||= shift @options;
	    if ($arg eq "cog") {
		$pv_copy_on_grow = 1;
	    } elsif ($arg eq "no-cog") {
		$pv_copy_on_grow = 0;
	    }
	} elsif ($opt eq "O") {
	    $arg = 1 if $arg eq "";
	    $pv_copy_on_grow = 0;
	    if ($arg >= 1) {
		# Optimisations for -O1
		$pv_copy_on_grow = 1;
	    }
	}
    }
    init_init();
    if (@options) {
	return sub {
	    my $objname;
	    foreach $objname (@options) {
		eval "save_object(\\$objname)";
	    }
	    output_all();
	}
    } else {
	return sub { save_main() };
    }
}

1;
