#      B.pm
#
#      Copyright (c) 1996 Malcolm Beattie
#
#      You may distribute under the terms of either the GNU General Public
#      License or the Artistic License, as specified in the README file.
#
package B;
require DynaLoader;
require Exporter;
@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(byteload_fh byteload_string minus_c ppname
		class peekop cast_I32 ad cstring cchar hash
		main_root main_start main_cv svref_2object
		walkoptree walkoptree_exec walksymtable
		comppadlist sv_undef compile_stats timing_info);

use strict;
@B::SV::ISA = 'B::OBJECT';
@B::NULL::ISA = 'B::SV';
@B::PV::ISA = 'B::SV';
@B::IV::ISA = 'B::SV';
@B::NV::ISA = 'B::IV';
@B::RV::ISA = 'B::SV';
@B::PVIV::ISA = qw(B::PV B::IV);
@B::PVNV::ISA = qw(B::PV B::NV);
@B::PVMG::ISA = 'B::PVNV';
@B::PVLV::ISA = 'B::PVMG';
@B::BM::ISA = 'B::PVMG';
@B::AV::ISA = 'B::PVMG';
@B::GV::ISA = 'B::PVMG';
@B::HV::ISA = 'B::PVMG';
@B::CV::ISA = 'B::PVMG';
@B::IO::ISA = 'B::CV';

@B::OP::ISA = 'B::OBJECT';
@B::UNOP::ISA = 'B::OP';
@B::BINOP::ISA = 'B::UNOP';
@B::LOGOP::ISA = 'B::UNOP';
@B::CONDOP::ISA = 'B::UNOP';
@B::LISTOP::ISA = 'B::BINOP';
@B::SVOP::ISA = 'B::OP';
@B::GVOP::ISA = 'B::OP';
@B::PVOP::ISA = 'B::OP';
@B::CVOP::ISA = 'B::OP';
@B::LOOP::ISA = 'B::LISTOP';
@B::PMOP::ISA = 'B::LISTOP';
@B::COP::ISA = 'B::OP';

@B::SPECIAL::ISA = 'B::OBJECT';

{
    # Stop "-w" from complaining about the lack of a real B::OBJECT class
    package B::OBJECT;
}

my $debug;
my $op_count = 0;

sub debug {
    my ($class, $value) = @_;
    $debug = $value;
}

# sub OPf_KIDS;
# add to .xs for perl5.002
sub OPf_KIDS () { 4 }

sub ad {
    my $obj = shift;
    return $$obj;
}

sub class {
    my $obj = shift;
    my $name = ref $obj;
    $name =~ s/^.*:://;
    return $name;
}

# For debugging
sub peekop {
    my $op = shift;
    return sprintf("%s (0x%x) %s", class($op), $$op, $op->ppaddr);
}

sub walkoptree {
    my($op, $method, $level) = @_;
    $op_count++; # just for statistics
    $level ||= 0;
    warn(sprintf("walkoptree: %d. %s\n", $level, peekop($op))) if $debug;
    $op->$method($level);
    if (ad($op) && ($op->flags & OPf_KIDS)) {
	my $kid;
	for ($kid = $op->first; $$kid; $kid = $kid->sibling) {
	    walkoptree($kid, $method, $level + 1);
	}
    }
}

sub compile_stats {
    return "Total number of OPs processed: $op_count\n";
}

sub timing_info {
    my ($sec, $min, $hr) = localtime;
    my ($user, $sys) = times;
    sprintf("%02d:%02d:%02d user=$user sys=$sys",
	    $hr, $min, $sec, $user, $sys);
}

my %symtable;
sub savesym {
    my ($obj, $value) = @_;
#    warn(sprintf("savesym: sym_%x => %s\n", ad($obj), $value)); # debug
    $symtable{sprintf("sym_%x", ad($obj))} = $value;
}

sub objsym {
    my $obj = shift;
    return $symtable{sprintf("sym_%x", ad($obj))};
}

sub walkoptree_exec {
    my ($op, $method, $level) = @_;
    my ($sym, $ppname);
    my $prefix = "    " x $level;
    for (; $$op; $op = $op->next) {
	$sym = objsym($op);
	if (defined($sym)) {
	    print $prefix, "goto $sym\n";
	    return;
	}
	savesym($op, sprintf("%s (0x%lx)", class($op), ad($op)));
	$op->$method($level);
	$ppname = $op->ppaddr;
	if ($ppname =~ /^pp_(or|and|mapwhile|grepwhile|entertry)$/) {
	    print $prefix, uc($1), " => {\n";
	    walkoptree_exec($op->other, $method, $level + 1);
	    print $prefix, "}\n";
	} elsif ($ppname eq "pp_match" || $ppname eq "pp_subst") {
	    my $pmreplstart = $op->pmreplstart;
	    if (ad($pmreplstart)) {
		print $prefix, "PMREPLSTART => {\n";
		walkoptree_exec($pmreplstart, $method, $level + 1);
		print $prefix, "}\n";
	    }
	} elsif ($ppname eq "pp_substcont") {
	    print $prefix, "SUBSTCONT => {\n";
	    walkoptree_exec($op->other->pmreplstart, $method, $level + 1);
	    print $prefix, "}\n";
	    $op = $op->other;
	} elsif ($ppname eq "pp_cond_expr") {
	    # pp_cond_expr never returns op_next
	    print $prefix, "TRUE => {\n";
	    walkoptree_exec($op->true, $method, $level + 1);
	    print $prefix, "}\n";
	    $op = $op->false;
	    redo;
	} elsif ($ppname eq "pp_range") {
	    print $prefix, "TRUE => {\n";
	    walkoptree_exec($op->true, $method, $level + 1);
	    print $prefix, "}\n", $prefix, "FALSE => {\n";
	    walkoptree_exec($op->false, $method, $level + 1);
	    print $prefix, "}\n";
	} elsif ($ppname eq "pp_enterloop") {
	    print $prefix, "REDO => {\n";
	    walkoptree_exec($op->redoop, $method, $level + 1);
	    print $prefix, "}\n", $prefix, "NEXT => {\n";
	    walkoptree_exec($op->nextop, $method, $level + 1);
	    print $prefix, "}\n", $prefix, "LAST => {\n";
	    walkoptree_exec($op->lastop,  $method, $level + 1);
	    print $prefix, "}\n";
	} elsif ($ppname eq "pp_subst") {
	    my $replstart = $op->pmreplstart;
	    if (ad($replstart)) {
		print $prefix, "SUBST => {\n";
		walkoptree_exec($replstart, $method, $level + 1);
		print $prefix, "}\n";
	    }
	}
    }
}

sub walksymtable {
    my ($symref, $method, $recurse) = @_;
    my $sym;
    no strict 'vars';
    local(*glob);
    while (($sym, *glob) = each %$symref) {
	if ($sym =~ /::$/) {
	    if ($sym ne "main::" && &$recurse($sym)) {
		walksymtable(\%glob, $method, $recurse);
	    }
	} else {
	    svref_2object(\*glob)->EGV->$method();
	}
    }
}

bootstrap B;

1;
