package B::Debug;
use strict;
use B qw(peekop class ad walkoptree walkoptree_exec
         main_start main_root cstring sv_undef);
use B::Asmdata qw(@specialsv_name);

sub B::OP::debug {
    my ($op) = @_;
    printf <<'EOT', class($op), ad($op), ad($op->next), ad($op->sibling), $op->ppaddr, $op->targ, $op->type, $op->seq, $op->flags, $op->private;
%s (0x%lx)
	op_next		0x%x
	op_sibling	0x%x
	op_ppaddr	%s
	op_targ		%d
	op_type		%d
	op_seq		%d
	op_flags	%d
	op_private	%d
EOT
}

sub B::UNOP::debug {
    my ($op) = @_;
    $op->B::OP::debug();
    printf "\top_first\t0x%x\n", ad($op->first);
}

sub B::BINOP::debug {
    my ($op) = @_;
    $op->B::UNOP::debug();
    printf "\top_last\t\t0x%x\n", ad($op->last);
}

sub B::LOGOP::debug {
    my ($op) = @_;
    $op->B::UNOP::debug();
    printf "\top_other\t0x%x\n", ad($op->other);
}

sub B::CONDOP::debug {
    my ($op) = @_;
    $op->B::UNOP::debug();
    printf "\top_true\t0x%x\n", ad($op->true);
    printf "\top_false\t0x%x\n", ad($op->false);
}

sub B::LISTOP::debug {
    my ($op) = @_;
    $op->B::BINOP::debug();
    printf "\top_children\t%d\n", $op->children;
}

sub B::PMOP::debug {
    my ($op) = @_;
    $op->B::LISTOP::debug();
    printf "\top_pmreplroot\t0x%x\n", ad($op->pmreplroot);
    printf "\top_pmreplstart\t0x%x\n", ad($op->pmreplstart);
    printf "\top_pmnext\t0x%x\n", ad($op->pmnext);
    printf "\top_pmregexp->precomp\t%s\n", cstring($op->precomp);
    printf "\top_pmshort\t0x%x\n", ad($op->pmshort);
    printf "\top_pmflags\t0x%x\n", $op->pmflags;
    printf "\top_pmslen\t%d\n", $op->pmslen;
    $op->pmshort->debug;
    $op->pmreplroot->debug;
}

sub B::COP::debug {
    my ($op) = @_;
    $op->B::OP::debug();
    my ($filegv) = $op->filegv;
    printf <<'EOT', $op->label, ad($op->stash), ad($filegv), $op->seq, $op->arybase, $op->line;
	cop_label	%s
	cop_stash	0x%x
	cop_filegv	0x%x
	cop_seq		%d
	cop_arybase	%d
	cop_line	%d
EOT
    $filegv->debug;
}

sub B::SVOP::debug {
    my ($op) = @_;
    $op->B::OP::debug();
    printf "\top_sv\t\t0x%x\n", ad($op->sv);
    $op->sv->debug;
}

sub B::PVOP::debug {
    my ($op) = @_;
    $op->B::OP::debug();
    printf "\top_pv\t\t0x%x\n", $op->pv;
}

sub B::GVOP::debug {
    my ($op) = @_;
    $op->B::OP::debug();
    printf "\top_gv\t\t0x%x\n", ad($op->gv);
}

sub B::CVOP::debug {
    my ($op) = @_;
    $op->B::OP::debug();
    printf "\top_cv\t\t0x%x\n", ad($op->cv);
}

sub B::NULL::debug {
    my ($sv) = @_;
    if (ad($sv) == ad(sv_undef())) {
	print "&sv_undef\n";
    } else {
	printf "NULL (0x%x)\n", ad($sv);
    }
}

sub B::SV::debug {
    my ($sv) = @_;
    if (!$$sv) {
	print class($sv), " = NULL\n";
	return;
    }
    printf <<'EOT', class($sv), ad($sv), $sv->REFCNT, $sv->FLAGS;
%s (0x%x)
	REFCNT		%d
	FLAGS		0x%x
EOT
}

sub B::PV::debug {
    my ($sv) = @_;
    $sv->B::SV::debug();
    my $pv = $sv->PV();
    printf <<'EOT', cstring($pv), length($pv);
	xpv_pv		%s
	xpv_cur		%d
EOT
}

sub B::IV::debug {
    my ($sv) = @_;
    $sv->B::SV::debug();
    printf "\txiv_iv\t\t%d\n", $sv->IV;
}

sub B::NV::debug {
    my ($sv) = @_;
    $sv->B::IV::debug();
    printf "\txnv_nv\t\t%s\n", $sv->NV;
}

sub B::PVIV::debug {
    my ($sv) = @_;
    $sv->B::PV::debug();
    printf "\txiv_iv\t\t%d\n", $sv->IV;
}

sub B::PVNV::debug {
    my ($sv) = @_;
    $sv->B::PVIV::debug();
    printf "\txnv_nv\t\t%s\n", $sv->NV;
}

sub B::PVLV::debug {
    my ($sv) = @_;
    $sv->B::PVNV::debug();
    printf "\txlv_targoff\t%d\n", $sv->TARGOFF;
    printf "\txlv_targlen\t%u\n", $sv->TARGLEN;
    printf "\txlv_type\t%s\n", cstring(chr($sv->TYPE));
}

sub B::BM::debug {
    my ($sv) = @_;
    $sv->B::PVNV::debug();
    printf "\txbm_useful\t%d\n", $sv->USEFUL;
    printf "\txbm_previous\t%u\n", $sv->PREVIOUS;
    printf "\txbm_rare\t%s\n", cstring(chr($sv->RARE));
}

sub B::CV::debug {
    my ($sv) = @_;
    $sv->B::PVNV::debug();
    my ($stash) = $sv->STASH;
    my ($start) = $sv->START;
    my ($root) = $sv->ROOT;
    my ($padlist) = $sv->PADLIST;
    my ($gv) = $sv->GV;
    my ($filegv) = $sv->FILEGV;
    printf <<'EOT', ad($stash), ad($start), ad($root), ad($gv), ad($filegv), $sv->DEPTH, $padlist, ad($sv->OUTSIDE);
	STASH		0x%x
	START		0x%x
	ROOT		0x%x
	GV		0x%x
	FILEGV		0x%x
	DEPTH		%d
	PADLIST		0x%x			       
	OUTSIDE		0x%x
EOT
    $start->debug if $start;
    $root->debug if $root;
    $gv->debug if $gv;
    $filegv->debug if $filegv;
    $padlist->debug if $padlist;
}

sub B::AV::debug {
    my ($av) = @_;
    $av->B::SV::debug;
    my(@array) = $av->ARRAY;
    print "\tARRAY\t\t(", join(", ", map("0x" . ad($_), @array)), ")\n";
    printf <<'EOT', scalar(@array), $av->MAX, $av->OFF, $av->AvFLAGS;
	FILL		%d    
	MAX		%d
	OFF		%d
	AvFLAGS		%d
EOT
}
    
sub B::GV::debug {
    my ($gv) = @_;
    my ($sv) = $gv->SV;
    my ($av) = $gv->AV;
    my ($cv) = $gv->CV;
    $gv->B::SV::debug;
    printf <<'EOT', $gv->NAME, $gv->STASH, ad($sv), $gv->GvREFCNT, $gv->FORM, ad($av), ad($gv->HV), ad($gv->EGV), ad($cv), $gv->CVGEN, $gv->LINE, $gv->FILEGV, $gv->GvFLAGS;
	NAME		%s
	STASH		0x%x
	SV		0x%x
	GvREFCNT	%d
	FORM		0x%x
	AV		0x%x
	HV		0x%x
	EGV		0x%x
	CV		0x%x
	CVGEN		%d
	LINE		%d
	FILEGV		0x%x
	GvFLAGS		0x%x
EOT
    $sv->debug if $sv;
    $av->debug if $av;
    $cv->debug if $cv;
}

sub B::SPECIAL::debug {
    my $sv = shift;
    print $specialsv_name[$$sv], "\n";
}

sub compile {
    my $order = shift;
    if ($order eq "exec") {
        return sub { walkoptree_exec(main_start, "debug") }
    } else {
        return sub { walkoptree(main_root, "debug") }
    }
}

1;
