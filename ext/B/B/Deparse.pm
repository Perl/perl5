# B::Deparse.pm
# Copyright (c) 1998 Stephen McCamant. All rights reserved.
# This module is free software; you can redistribute and/or modify
# it under the same terms as Perl itself.

# This is based on the module of the same name by Malcolm Beattie,
# but essentially none of his code remains.

package B::Deparse;
use Carp 'cluck';
use B qw(class main_root main_start main_cv svref_2object);
$VERSION = 0.51;
use strict;

# Changes between 0.50 and 0.51:
# - fixed nulled leave with live enter in sort { }
# - fixed reference constants (\"str")
# - handle empty programs gracefully
# - handle infinte loops (for (;;) {}, while (1) {})
# - differentiate between `for my $x ...' and `my $x; for $x ...'
# - various minor cleanups
# - moved globals into an object
# - added `-u', like B::C
# - package declarations using cop_stash
# - subs, formats and code sorted by cop_seq

# Todo:
# - eliminate superfluous parentheses
# - 'EXPR1 && EXPR2;' => 'EXPR2 if EXPR1;'
# - pp_threadsv (incl. in foreach)
# - style options
# - '&&' => 'and'?
# - ',' => '=>' (auto-unquote?)
# - break long lines ("\r" as discretionary break?)
# - version using op_next instead of op_first/sibling?
# - avoid string copies (pass arrays, one big join?)
# - auto-apply `-u'?
# - documentation

# The following OPs don't have functions:

# pp_threadsv -- see Todo

# pp_padany -- does not exist after parsing
# pp_rcatline -- does not exist

# pp_leavesub -- see deparse_sub
# pp_leavewrite -- see deparse_format
# pp_method -- see entersub
# pp_regcmaybe -- see regcomp
# pp_substcont -- see subst
# pp_grepstart -- see grepwhile
# pp_mapstart -- see mapwhile
# pp_flip -- see flop
# pp_iter -- see leaveloop
# pp_enterloop -- see leaveloop
# pp_leaveeval -- see entereval
# pp_entertry -- see leavetry

# Object fields (were globals):
#
# avoid_local:
# (local($a), local($b)) and local($a, $b) have the same internal
# representation but the short form looks better. We notice we can
# use a large-scale local when checking the list, but need to prevent
# individual locals too. This hash holds the addresses of OPs that 
# have already had their local-ness accounted for. The same thing
# is done with my().
#
# curcv:
# CV for current sub (or main program) being deparsed
#
# curstash:
# name of the current package for deparsed code
#
# subs_todo:
# array of [cop_seq, GV, is_format?] for subs and formats we still
# want to deparse
#
# subs_done, forms_done:
# keys are addresses of GVs for subs and formats we've already
# deparsed (or at least put into subs_todo)

sub null {
    my $op = shift;
    return class($op) eq "NULL";
}

sub todo {
    my $self = shift;
    my($gv, $cv, $is_form) = @_;
    my $seq;
    if (!null($cv->START) and is_state($cv->START)) {
	$seq = $cv->START->cop_seq;
    } else {
	$seq = 0;
    }
    push @{$self->{'subs_todo'}}, [$seq, $gv, $is_form];
}

sub next_todo {
    my $self = shift;
    my $ent = shift @{$self->{'subs_todo'}};
    my $name = $self->gv_name($ent->[1]);
    if ($ent->[2]) {
	return "format $name =\n"
	    . $self->deparse_format($ent->[1]->FORM). "\n";
    } else {
	return "sub $name " .
	    $self->deparse_sub($ent->[1]->CV);
    }
}

sub OPf_KIDS () { 4 }

sub walk_tree {
    my($op, $sub) = @_;
    $sub->($op);
    if ($op->flags & OPf_KIDS) {
	my $kid;
	for ($kid = $op->first; not null $kid; $kid = $kid->sibling) {
	    walk_tree($kid, $sub);
	}
    }
}

sub walk_sub {
    my $self = shift;
    my $cv = shift;
    my $op = $cv->ROOT;
    $op = shift if null $op;
    return if !$op or null $op;
    walk_tree($op, sub {
	my $op = shift;
	if ($op->ppaddr eq "pp_gv") {
	    if ($op->next->ppaddr eq "pp_entersub") {
		next if $self->{'subs_done'}{$ {$op->gv}}++;
		next if class($op->gv->CV) eq "SPECIAL";
		$self->todo($op->gv, $op->gv->CV, 0);
		$self->walk_sub($op->gv->CV);
	    } elsif ($op->next->ppaddr eq "pp_enterwrite"
		     or ($op->next->ppaddr eq "pp_rv2gv"
			 and $op->next->next->ppaddr eq "pp_enterwrite")) {
		next if $self->{'forms_done'}{$ {$op->gv}}++;
		next if class($op->gv->FORM) eq "SPECIAL";
		$self->todo($op->gv, $op->gv->FORM, 1);
		$self->walk_sub($op->gv->FORM);
	    }
	}
    });
}

sub stash_subs {
    my $self = shift;
    my $pack = shift;
    my(%stash, @ret);
    { no strict 'refs'; %stash = svref_2object(\%{$pack . "::"})->ARRAY }
    my($key, $val);
    while (($key, $val) = each %stash) {
	next unless class($val) eq "GV";
	if (class($val->CV) ne "SPECIAL") {
	    next if $self->{'subs_done'}{$$val}++;
	    $self->todo($val, $val->CV, 0);
	    $self->walk_sub($val->CV);
	}
	if (class($val->FORM) ne "SPECIAL") {
	    next if $self->{'forms_done'}{$$val}++;
	    $self->todo($val, $val->FORM, 1);
	    $self->walk_sub($val->FORM);
	}
    }
}

sub compile {
    my(@args) = @_;
    return sub { 
	my $self = bless {};
	my $arg;
	$self->{'subs_todo'} = [];
	$self->stash_subs("main");
	$self->{'curcv'} = main_cv;
	$self->{'curstash'} = "main";
	while ($arg = shift @args) {
	    if (substr($arg, 0, 2) eq "-u") {
		$self->stash_subs(substr($arg, 2));
	    }
	}
	$self->walk_sub(main_cv, main_start);
	@{$self->{'subs_todo'}} =
	    sort {$a->[0] <=> $b->[0]} @{$self->{'subs_todo'}};
	print indent($self->deparse(main_root)), "\n" unless null main_root;
	my @text;
	while (scalar(@{$self->{'subs_todo'}})) {
	    push @text, $self->next_todo;
	}
	print indent(join("", @text)), "\n" if @text;
    }
}

sub deparse {
    my $self = shift;
    my $op = shift;
#    cluck unless ref $op;
    my $meth = $op->ppaddr;
    return $self->$meth($op);
}

sub indent {
    my $txt = shift;
    my @lines = split(/\n/, $txt);
    my $leader = "";
    my $line;
    for $line (@lines) {
	if (substr($line, 0, 1) eq "\t") {
	    $leader = $leader . "    ";
	    $line = substr($line, 1);
	} elsif (substr($line, 0, 1) eq "\b") {
	    $leader = substr($leader, 0, length($leader) - 4);
	    $line = substr($line, 1);
	}
	$line = $leader . $line;
    }
    return join("\n", @lines);
}

sub SVf_POK () {0x40000}

sub deparse_sub {
    my $self = shift;
    my $cv = shift;
    my $proto = "";
    if ($cv->FLAGS & SVf_POK) {
	$proto = "(". $cv->PV . ") ";
    }
    local($self->{'curcv'}) = $cv;
    local($self->{'curstash'}) = $self->{'curstash'};
    if (not null $cv->ROOT) {
	# skip leavesub
	return $proto . "{\n\t" . 
	    $self->deparse($cv->ROOT->first) . "\n\b}\n"; 
    } else { # XSUB?
	return $proto  . "{}\n";
    }
}

sub deparse_format {
    my $self = shift;
    my $form = shift;
    my @text;
    local($self->{'curcv'}) = $form;
    local($self->{'curstash'}) = $self->{'curstash'};
    my $op = $form->ROOT;
    my $kid;
    $op = $op->first->first; # skip leavewrite, lineseq
    while (not null $op) {
	$op = $op->sibling; # skip nextstate
	my @exprs;
	$kid = $op->first->sibling; # skip pushmark
	push @text, $kid->sv->PV;
	$kid = $kid->sibling;
	for (; not null $kid; $kid = $kid->sibling) {
	    push @exprs, $self->deparse($kid);
	}
	push @text, join(", ", @exprs)."\n" if @exprs;
	$op = $op->sibling;
    }
    return join("", @text) . ".";
}

# the aassign in-common check messes up SvCUR (always setting it
# to a value >= 100), but it's probably safe to assume there
# won't be any NULs in the names of my() variables. (with
# stash variables, I wouldn't be so sure)
sub padname_fix {
    my $str = shift;
    $str = substr($str, 0, index($str, "\0")) if index($str, "\0") != -1;
    return $str;
}

sub is_scope {
    my $op = shift;
    return $op->ppaddr eq "pp_leave" || $op->ppaddr eq "pp_scope"
	|| ($op->ppaddr eq "pp_null" && class($op) eq "UNOP" 
	    && (is_scope($op->first) || $op->first->ppaddr eq "pp_enter"));
}

sub is_state {
    my $name = $_[0]->ppaddr;
    return $name eq "pp_nextstate" || $name eq "pp_dbstate";
}

sub is_miniwhile { # check for one-line loop (`foo() while $y--')
    my $op = shift;
    return (!null($op) and null($op->sibling) 
	    and $op->ppaddr eq "pp_null" and class($op) eq "UNOP"
	    and (($op->first->ppaddr =~ /^pp_(and|or)$/
		  and $op->first->first->sibling->ppaddr eq "pp_lineseq")
		 or ($op->first->ppaddr eq "pp_lineseq"
		     and not null $op->first->first->sibling
		     and $op->first->first->sibling->ppaddr eq "pp_unstack")
		 ));
}

sub is_scalar {
    my $op = shift;
    return ($op->ppaddr eq "pp_rv2sv" or
	    $op->ppaddr eq "pp_padsv" or
	    $op->ppaddr eq "pp_gv" or # only in array/hash constructs
	    !null($op->first) && $op->first->ppaddr eq "pp_gvsv");
}

sub OPp_LVAL_INTRO () { 128 }

sub maybe_local {
    my $self = shift;
    my($op, $text) = @_;
    if ($op->private & OPp_LVAL_INTRO and not $self->{'avoid_local'}{$$op}) {
	return "local(" . $text . ")";
    } else {
	return $text;
    }
}

sub padname_sv {
    my $self = shift;
    my $targ = shift;
    return (($self->{'curcv'}->PADLIST->ARRAY)[0]->ARRAY)[$targ];
}

sub maybe_my {
    my $self = shift;
    my($op, $text) = @_;
    if ($op->private & OPp_LVAL_INTRO and not $self->{'avoid_local'}{$$op}) {
	return "my(" . $text . ")";
    } else {
	return $text;
    }
}

sub pp_enter {cluck "unexpected OP_ENTER"; ""} # see also leave

# leave, scope, and lineseq should probably share code
sub pp_leave {
    my $self = shift;
    my $op = shift;
    my ($kid, $expr);
    my @exprs;
    local($self->{'curstash'}) = $self->{'curstash'};
    $kid = $op->first->sibling; # skip enter
    if (is_miniwhile($kid)) {
	my $top = $kid->first;
	my $name = $top->ppaddr;
	if ($name eq "pp_and") {
	    $name = "while";
	} elsif ($name eq "pp_or") {
	    $name = "until";
	} else { # no conditional -> while 1 or until 0
	    return $self->deparse($top->first) . " while 1";
	}
	my $cond = $top->first;
	my $body = $cond->sibling;
	$cond = $self->deparse($cond);
	$body = $self->deparse($body);
	return "$body $name $cond";
    }
    for (; !null($kid); $kid = $kid->sibling) {
	$expr = "";
	if (is_state $kid) {
	    $expr = $self->deparse($kid);
	    $kid = $kid->sibling;
	    last if null $kid;
	}
	$expr .= $self->deparse($kid);
	if (is_scope($kid) and not is_miniwhile($kid->first->sibling)) {
	    $expr = "do {$expr}";
	}
	push @exprs, $expr if $expr;
    }
    return join(";\n", @exprs);
}

sub pp_scope {
    my $self = shift;
    my $op = shift;
    my ($kid, $expr);
    my @exprs;
    for ($kid = $op->first; !null($kid); $kid = $kid->sibling) {
	$expr = "";
	if (is_state $kid) {
	    $expr = $self->deparse($kid);
	    $kid = $kid->sibling;
	    last if null $kid;
	}
	$expr .= $self->deparse($kid);
	if (is_scope($kid)) {
	    $expr = "do {$expr}";
	}
	push @exprs, $expr if $expr;
    }
    return join("; ", @exprs);
}

sub pp_lineseq {
    my $self = shift;
    my $op = shift;
    my ($kid, $expr);
    my @exprs;
    for ($kid = $op->first; !null($kid); $kid = $kid->sibling) {
	$expr = "";
	if (is_state $kid) {
	    $expr = $self->deparse($kid);
	    $kid = $kid->sibling;
	    last if null $kid;
	}
	$expr .= $self->deparse($kid);
	if (is_scope($kid) and not is_miniwhile($kid->first->sibling)) {
	    $expr = "do {$expr}";
	}
	push @exprs, $expr if $expr;
    }
    return join(";\n", @exprs);
}

# The BEGIN {} is used here because otherwise this code isn't executed
# when you run B::Deparse on itself.
my %globalnames;
BEGIN { map($globalnames{$_}++, "SIG", "STDIN", "STDOUT", "STDERR", "INC",
	    "ENV", "ARGV", "ARGVOUT", "_"); }

sub gv_name {
    my $self = shift;
    my $gv = shift;
    my $stash = $gv->STASH->NAME;
    my $name = $gv->NAME;
    if ($stash eq $self->{'curstash'} or $globalnames{$name}) {
	$stash = "";
    } else {
	$stash = $stash . "::";
    }
    if ($name =~ /^([\cA-\cZ])$/) {
	$name = "^" . chr(64 + ord($1));
    }
    return $stash . $name;
}

# Notice how subs and formats are inserted between statements here
sub pp_nextstate {
    my $self = shift;
    my $op = shift;
    my @text;
    @text = $op->label . ": " if $op->label;
    my $seq = $op->cop_seq;
    while (scalar(@{$self->{'subs_todo'}})
	   and $seq > $self->{'subs_todo'}[0][0]) {
	push @text, $self->next_todo;
    }
    my $stash = $op->stash->NAME;
    if ($stash ne $self->{'curstash'}) {
	push @text, "package $stash;\n";
	$self->{'curstash'} = $stash;
    }
    return join("", @text);
}

sub pp_dbstate { pp_nextstate(@_) }

sub pp_unstack { return "" } # see also leaveloop

sub baseop {
    my $self = shift;
    my($op, $name) = @_;
    return $name;
}

sub pp_stub { baseop(@_, "()") }
sub pp_wantarray { baseop(@_, "wantarray") }
sub pp_fork { baseop(@_, "fork") }
sub pp_wait { baseop(@_, "wait") }
sub pp_getppid { baseop(@_, "getppid") }
sub pp_time { baseop(@_, "time") }
sub pp_tms { baseop(@_, "times") }
sub pp_ghostent { baseop(@_, "gethostent") }
sub pp_gnetent { baseop(@_, "getnetent") }
sub pp_gprotoent { baseop(@_, "getprotoent") }
sub pp_gservent { baseop(@_, "getservent") }
sub pp_ehostent { baseop(@_, "endhostent") }
sub pp_enetent { baseop(@_, "endnetent") }
sub pp_eprotoent { baseop(@_, "endprotoent") }
sub pp_eservent { baseop(@_, "endservent") }
sub pp_gpwent { baseop(@_, "getpwent") }
sub pp_spwent { baseop(@_, "setpwent") }
sub pp_epwent { baseop(@_, "endpwent") }
sub pp_ggrent { baseop(@_, "getgrent") }
sub pp_sgrent { baseop(@_, "setgrent") }
sub pp_egrent { baseop(@_, "endgrent") }
sub pp_getlogin { baseop(@_, "getlogin") }

sub POSTFIX () { 1 }

sub OPf_SPECIAL () { 128 }

sub unop {
    my $self = shift;
    my($op, $name, $flags) = (@_, 0);
    my $kid;
    if (class($op) eq "UNOP") {
	$kid = $op->first;
	$kid = "(" . $self->deparse($kid) . ")";
    } else {
	$kid = ($op->flags & OPf_SPECIAL ? "()" : "");
    }
    return ($flags & POSTFIX) ? "$kid$name" : "$name$kid";
}

sub pp_preinc { unop(@_, "++") }
sub pp_predec { unop(@_, "--") }
sub pp_postinc { unop(@_, "++", POSTFIX) }
sub pp_postdec { unop(@_, "--", POSTFIX) }
sub pp_i_preinc { unop(@_, "++") }
sub pp_i_predec { unop(@_, "--") }
sub pp_i_postinc { unop(@_, "++", POSTFIX) }
sub pp_i_postdec { unop(@_, "--", POSTFIX) }
sub pp_negate { unop(@_, "-") }
sub pp_i_negate { unop(@_, "-") }
sub pp_not { unop(@_, "!") }
sub pp_complement { unop(@_, "~") }

sub pp_chop { unop(@_, "chop") }
sub pp_chomp { unop(@_, "chomp") }
sub pp_schop { unop(@_, "chop") }
sub pp_schomp { unop(@_, "chomp") }
sub pp_defined { unop(@_, "defined") }
sub pp_undef { unop(@_, "undef") }
sub pp_study { unop(@_, "study") }
sub pp_scalar { unop(@_, "scalar") }
sub pp_ref { unop(@_, "ref") }
sub pp_pos { maybe_local(@_, unop(@_, "pos")) }

sub pp_sin { unop(@_, "sin") }
sub pp_cos { unop(@_, "cos") }
sub pp_rand { unop(@_, "rand") }
sub pp_srand { unop(@_, "srand") }
sub pp_exp { unop(@_, "exp") }
sub pp_log { unop(@_, "log") }
sub pp_sqrt { unop(@_, "sqrt") }
sub pp_int { unop(@_, "int") }
sub pp_hex { unop(@_, "hex") }
sub pp_oct { unop(@_, "oct") }
sub pp_abs { unop(@_, "abs") }

sub pp_length { unop(@_, "length") }
sub pp_ord { unop(@_, "ord") }
sub pp_chr { unop(@_, "chr") }
sub pp_ucfirst { unop(@_, "ucfirst") }
sub pp_lcfirst { unop(@_, "lcfirst") }
sub pp_uc { unop(@_, "uc") }
sub pp_lc { unop(@_, "lc") }
sub pp_quotemeta { unop(@_, "quotemeta") }

sub pp_each { unop(@_, "each") }
sub pp_values { unop(@_, "values") }
sub pp_keys { unop(@_, "keys") }
sub pp_pop { unop(@_, "pop") }
sub pp_shift { unop(@_, "shift") }

sub pp_caller { unop(@_, "caller") }
sub pp_reset { unop(@_, "reset") }
sub pp_exit { unop(@_, "exit") }
sub pp_prototype { unop(@_, "prototype") }

sub pp_close { unop(@_, "close") }
sub pp_fileno { unop(@_, "fileno") }
sub pp_umask { unop(@_, "umask") }
sub pp_binmode { unop(@_, "binmode") }
sub pp_untie { unop(@_, "untie") }
sub pp_tied { unop(@_, "tied") }
sub pp_dbmclose { unop(@_, "dbmclose") }
sub pp_getc { unop(@_, "getc") }
sub pp_eof { unop(@_, "eof") }
sub pp_tell { unop(@_, "tell") }
sub pp_getsockname { unop(@_, "getsockname") }
sub pp_getpeername { unop(@_, "getpeername") }

sub pp_chdir { unop(@_, "chdir") }
sub pp_chroot { unop(@_, "chroot") }
sub pp_readlink { unop(@_, "readlink") }
sub pp_rmdir { unop(@_, "rmdir") }
sub pp_readdir { unop(@_, "readdir") }
sub pp_telldir { unop(@_, "telldir") }
sub pp_rewinddir { unop(@_, "rewinddir") }
sub pp_closedir { unop(@_, "closedir") }
sub pp_getpgrp { unop(@_, "getpgrp") }
sub pp_localtime { unop(@_, "localtime") }
sub pp_gmtime { unop(@_, "gmtime") }
sub pp_alarm { unop(@_, "alarm") }
sub pp_sleep { unop(@_, "sleep") }

sub pp_dofile { unop(@_, "do") }
sub pp_entereval { unop(@_, "eval") }

sub pp_ghbyname { unop(@_, "gethostbyname") }
sub pp_gnbyname { unop(@_, "getnetbyname") }
sub pp_gpbyname { unop(@_, "getprotobyname") }
sub pp_shostent { unop(@_, "sethostent") }
sub pp_snetent { unop(@_, "setnetent") }
sub pp_sprotoent { unop(@_, "setprotoent") }
sub pp_sservent { unop(@_, "setservent") }
sub pp_gpwnam { unop(@_, "getpwnam") }
sub pp_gpwuid { unop(@_, "getpwuid") }
sub pp_ggrnam { unop(@_, "getgrnam") }
sub pp_ggrgid { unop(@_, "getgrgid") }

sub pp_lock { unop(@_, "lock") }

sub pp_exists {
    my $self = shift;
    my $op = shift;
    return "exists(" . $self->pp_helem($op->first) . ")";
}

sub OPpSLICE () { 64 }

sub pp_delete {
    my $self = shift;
    my $op = shift;
    my $arg;
    if ($op->private & OPpSLICE) {
	$arg = $self->pp_hslice($op->first);
    } else {
	$arg = $self->pp_helem($op->first);
    }
    return "delete($arg)";
}

sub OPp_CONST_BARE () { 64 }

sub pp_require {
    my $self = shift;
    my $op = shift;
    if (class($op) eq "UNOP" and $op->first->ppaddr eq "pp_const"
	and $op->first->private & OPp_CONST_BARE)
    {
	my $name = $op->first->sv->PV;
	$name =~ s[/][::]g;
	$name =~ s/\.pm//g;
	return "require($name)";
    } else {	
	$self->unop($op, "require");
    }
}

sub padval {
    my $self = shift;
    my $targ = shift;
    return (($self->{'curcv'}->PADLIST->ARRAY)[1]->ARRAY)[$targ];
}

sub pp_refgen {
    my $self = shift;	
    my $op = shift;
    my $kid = $op->first;
    if ($kid->ppaddr eq "pp_null") {
	$kid = $kid->first;
	if ($kid->ppaddr eq "pp_anonlist" || $kid->ppaddr eq "pp_anonhash") {
	    my($pre, $post) = @{{"pp_anonlist" => ["[","]"],
				 "pp_anonhash" => ["{","}"]}->{$kid->ppaddr}};
	    my($expr, @exprs);
	    $kid = $kid->first->sibling; # skip pushmark
	    for (; !null($kid); $kid = $kid->sibling) {
		$expr = $self->deparse($kid);
		push @exprs, $expr;
	    }
	    return $pre . join(", ", @exprs) . $post;
	} elsif (!null($kid->sibling) and 
		 $kid->sibling->ppaddr eq "pp_anoncode") {
	    return "sub " .
		$self->deparse_sub($self->padval($kid->sibling->targ));
	}
    }
    $self->unop($op, "\\");
}

sub pp_srefgen { pp_refgen(@_) }

sub pp_readline {
    my $self = shift;
    my $op = shift;
    my $kid = $op->first;
    $kid = $kid->first if $kid->ppaddr eq "pp_rv2gv"; # <$fh>
    if ($kid->ppaddr eq "pp_rv2gv") {
	$kid = $kid->first;
    }
    return "<" . $self->deparse($kid) . ">";
}

sub loopex {
    my $self = shift;
    my ($op, $name) = @_;
    my $kid;
    if (class($op) eq "PVOP") {
	$kid = " " . $op->pv;
    } elsif (class($op) eq "BASEOP") {
	$kid = "";
    } elsif (class($op) eq "UNOP") {
	$kid = "(" . $self->deparse($op->first) . ")";
    }
    return "$name$kid";
}

sub pp_last { loopex(@_, "last") }
sub pp_next { loopex(@_, "next") }
sub pp_redo { loopex(@_, "redo") }
sub pp_goto { loopex(@_, "goto") }
sub pp_dump { loopex(@_, "dump") }

sub ftst {
    my $self = shift;
    my($op, $name) = @_;
    my $kid;
    if (class($op) eq "UNOP") {
	$kid = $op->first;
	$kid = "(" . $self->deparse($kid) . ")";
    } elsif (class($op) eq "GVOP") {
	$kid = "(" . $self->pp_gv($op) . ")";
    } else { # I don't think baseop filetests ever survive ck_ftst, but...
	$kid = "";
    }
    return "$name$kid";
}

sub pp_lstat { ftst(@_, "lstat") }
sub pp_stat { ftst(@_, "stat") }
sub pp_ftrread { ftst(@_, "-R") }
sub pp_ftrwrite { ftst(@_, "-W") }
sub pp_ftrexec { ftst(@_, "-X") }
sub pp_fteread { ftst(@_, "-r") }
sub pp_ftewrite { ftst(@_, "-r") }
sub pp_fteexec { ftst(@_, "-r") }
sub pp_ftis { ftst(@_, "-e") }
sub pp_fteowned { ftst(@_, "-O") }
sub pp_ftrowned { ftst(@_, "-o") }
sub pp_ftzero { ftst(@_, "-z") }
sub pp_ftsize { ftst(@_, "-s") }
sub pp_ftmtime { ftst(@_, "-M") }
sub pp_ftatime { ftst(@_, "-A") }
sub pp_ftctime { ftst(@_, "-C") }
sub pp_ftsock { ftst(@_, "-S") }
sub pp_ftchr { ftst(@_, "-c") }
sub pp_ftblk { ftst(@_, "-b") }
sub pp_ftfile { ftst(@_, "-f") }
sub pp_ftdir { ftst(@_, "-d") }
sub pp_ftpipe { ftst(@_, "-p") }
sub pp_ftlink { ftst(@_, "-l") }
sub pp_ftsuid { ftst(@_, "-u") }
sub pp_ftsgid { ftst(@_, "-g") }
sub pp_ftsvtx { ftst(@_, "-k") }
sub pp_fttty { ftst(@_, "-t") }
sub pp_fttext { ftst(@_, "-T") }
sub pp_ftbinary { ftst(@_, "-B") }

sub SWAP_CHILDREN () { 1 }
sub ASSIGN () { 2 } # has OP= variant

sub OPf_STACKED () { 64 }

sub binop {
    my $self = shift;
    my ($op, $opname, $flags) = (@_, 0);
    my $left = $op->first;
    my $right = $op->last;
    my $eq = ($op->flags & OPf_STACKED && $flags & ASSIGN) ? "=" : "";
    if ($flags & SWAP_CHILDREN) {
	($left, $right) = ($right, $left);
    }
    $left = $self->deparse($left);
    $right = $self->deparse($right);
    return "($left $opname$eq $right)";
}

sub pp_add { binop(@_, "+", ASSIGN) }
sub pp_multiply { binop(@_, "*", ASSIGN) }
sub pp_subtract { binop(@_, "-", ASSIGN) }
sub pp_divide { binop(@_, "/", ASSIGN) }
sub pp_modulo { binop(@_, "%", ASSIGN) }
sub pp_i_add { binop(@_, "+", ASSIGN) }
sub pp_i_multiply { binop(@_, "*", ASSIGN) }
sub pp_i_subtract { binop(@_, "-", ASSIGN) }
sub pp_i_divide { binop(@_, "/", ASSIGN) }
sub pp_i_modulo { binop(@_, "%", ASSIGN) }
sub pp_pow { binop(@_, "**", ASSIGN) }

sub pp_left_shift { binop(@_, "<<", ASSIGN) }
sub pp_right_shift { binop(@_, ">>", ASSIGN) }
sub pp_bit_and { binop(@_, "&", ASSIGN) }
sub pp_bit_or { binop(@_, "|", ASSIGN) }
sub pp_bit_xor { binop(@_, "^", ASSIGN) }

sub pp_eq { binop(@_, "==") }
sub pp_ne { binop(@_, "!=") }
sub pp_lt { binop(@_, "<") }
sub pp_gt { binop(@_, ">") }
sub pp_ge { binop(@_, ">=") }
sub pp_le { binop(@_, "<=") }
sub pp_ncmp { binop(@_, "<=>") }
sub pp_i_eq { binop(@_, "==") }
sub pp_i_ne { binop(@_, "!=") }
sub pp_i_lt { binop(@_, "<") }
sub pp_i_gt { binop(@_, ">") }
sub pp_i_ge { binop(@_, ">=") }
sub pp_i_le { binop(@_, "<=") }
sub pp_i_ncmp { binop(@_, "<=>") }

sub pp_seq { binop(@_, "eq") }
sub pp_sne { binop(@_, "ne") }
sub pp_slt { binop(@_, "lt") }
sub pp_sgt { binop(@_, "gt") }
sub pp_sge { binop(@_, "ge") }
sub pp_sle { binop(@_, "le") }
sub pp_scmp { binop(@_, "cmp") }

sub pp_sassign { binop(@_, "=", SWAP_CHILDREN) }
sub pp_aassign { binop(@_, "=", SWAP_CHILDREN) }

# `.' is special because concats-of-concats are optimized to save copying
# by making all but the first concat stacked. The effect is as if the
# programmer had written `($a . $b) .= $c', except legal.
sub pp_concat {
    my $self = shift;
    my $op = shift;
    my $left = $op->first;
    my $right = $op->last;
    my $eq = "";
    if ($op->flags & OPf_STACKED and $op->first->ppaddr ne "pp_concat") {
	$eq = "=";
    }
    $left = $self->deparse($left);
    $right = $self->deparse($right);
    return "($left .$eq $right)";
}

# `x' is weird when the left arg is a list
sub pp_repeat {
    my $self = shift;
    my $op = shift;
    my $left = $op->first;
    my $right = $op->last;
    my $eq = ($op->flags & OPf_STACKED) ? "=" : "";
    if (null($right)) { # list repeat; count is inside left-side ex-list
	my $kid = $left->first->sibling; # skip pushmark
	my @exprs;
	for (; !null($kid->sibling); $kid = $kid->sibling) {
	    push @exprs, $self->deparse($kid);
	}
	$right = $kid;
	$left = "(" . join(", ", @exprs). ")";
    } else {
	$left = $self->deparse($left);
    }
    $right = $self->deparse($right);
    return "($left x$eq $right)";
}

sub range {
    my $self = shift;
    my ($op, $type) = @_;
    my $left = $op->first;
    my $right = $left->sibling;
    $left = $self->deparse($left);
    $right = $self->deparse($right);
    return "($left " . $type . " $right)";
}

sub pp_flop {
    my $self = shift;
    my $op = shift;
    my $flip = $op->first;
    my $type = ($flip->flags & OPf_SPECIAL) ? "..." : "..";
    return $self->range($flip->first, $type);
}

# one-line while/until is handled in pp_leave

sub logop {
    my $self = shift;
    my ($op, $opname, $blockname) = @_;
    my $left = $op->first;
    my $right = $op->first->sibling;
    $left = $self->deparse($left);
    my $scope = is_scope($right);
    $right = $self->deparse($right);
    if ($scope) {
	return "$blockname ($left) {\n\t$right\n\b}";
    } else {
	return "($left $opname $right)";
    }
}

sub pp_and { logop(@_, "&&", "if") }
sub pp_or { logop(@_, "||", "unless") }
sub pp_xor { logop(@_, "xor", "n/a") }

sub logassignop {
    my $self = shift;
    my ($op, $opname) = @_;
    my $left = $op->first;
    my $right = $op->first->sibling->first; # skip sassign
    $left = $self->deparse($left);
    $right = $self->deparse($right);
    return "($left $opname $right)";
}

sub pp_andassign { logassignop(@_, "&&=") }
sub pp_orassign { logassignop(@_, "||=") }

sub listop {
    my $self = shift;
    my($op, $name) = @_;
    my($kid, $expr, @exprs);
    for ($kid = $op->first->sibling; !null($kid); $kid = $kid->sibling) {
	$expr = $self->deparse($kid);
	push @exprs, $expr;
    }
    return "$name(" . join(", ", @exprs) . ")";
}

sub pp_bless { listop(@_, "bless") }
sub pp_atan2 { listop(@_, "atan2") }
sub pp_substr { maybe_local(@_, listop(@_, "substr")) }
sub pp_vec { maybe_local(@_, listop(@_, "vec")) }
sub pp_index { listop(@_, "index") }
sub pp_rindex { listop(@_, "rindex") }
sub pp_sprintf { listop(@_, "sprintf") }
sub pp_formline { listop(@_, "formline") } # see also deparse_format
sub pp_crypt { listop(@_, "crypt") }
sub pp_unpack { listop(@_, "unpack") }
sub pp_pack { listop(@_, "pack") }
sub pp_join { listop(@_, "join") }
sub pp_splice { listop(@_, "splice") }
sub pp_push { listop(@_, "push") }
sub pp_unshift { listop(@_, "unshift") }
sub pp_reverse { listop(@_, "reverse") }
sub pp_warn { listop(@_, "warn") }
sub pp_die { listop(@_, "die") }
sub pp_return { listop(@_, "return") }
sub pp_open { listop(@_, "open") }
sub pp_pipe_op { listop(@_, "pipe") }
sub pp_tie { listop(@_, "tie") }
sub pp_dbmopen { listop(@_, "dbmopen") }
sub pp_sselect { listop(@_, "select") }
sub pp_select { listop(@_, "select") }
sub pp_read { listop(@_, "read") }
sub pp_sysopen { listop(@_, "sysopen") }
sub pp_sysseek { listop(@_, "sysseek") }
sub pp_sysread { listop(@_, "sysread") }
sub pp_syswrite { listop(@_, "syswrite") }
sub pp_send { listop(@_, "send") }
sub pp_recv { listop(@_, "recv") }
sub pp_seek { listop(@_, "seek") }
sub pp_truncate { listop(@_, "truncate") }
sub pp_fcntl { listop(@_, "fcntl") }
sub pp_ioctl { listop(@_, "ioctl") }
sub pp_flock { listop(@_, "flock") }
sub pp_socket { listop(@_, "socket") }
sub pp_sockpair { listop(@_, "sockpair") }
sub pp_bind { listop(@_, "bind") }
sub pp_connect { listop(@_, "connect") }
sub pp_listen { listop(@_, "listen") }
sub pp_accept { listop(@_, "accept") }
sub pp_shutdown { listop(@_, "shutdown") }
sub pp_gsockopt { listop(@_, "getsockopt") }
sub pp_ssockopt { listop(@_, "setsockopt") }
sub pp_chown { listop(@_, "chown") }
sub pp_unlink { listop(@_, "unlink") }
sub pp_chmod { listop(@_, "chmod") }
sub pp_utime { listop(@_, "utime") }
sub pp_rename { listop(@_, "rename") }
sub pp_link { listop(@_, "link") }
sub pp_symlink { listop(@_, "symlink") }
sub pp_mkdir { listop(@_, "mkdir") }
sub pp_open_dir { listop(@_, "opendir") }
sub pp_seekdir { listop(@_, "seekdir") }
sub pp_waitpid { listop(@_, "waitpid") }
sub pp_system { listop(@_, "system") }
sub pp_exec { listop(@_, "exec") }
sub pp_kill { listop(@_, "kill") }
sub pp_setpgrp { listop(@_, "setpgrp") }
sub pp_getpriority { listop(@_, "getpriority") }
sub pp_setpriority { listop(@_, "setpriority") }
sub pp_shmget { listop(@_, "shmget") }
sub pp_shmctl { listop(@_, "shmctl") }
sub pp_shmread { listop(@_, "shmread") }
sub pp_shmwrite { listop(@_, "shmwrite") }
sub pp_msgget { listop(@_, "msgget") }
sub pp_msgctl { listop(@_, "msgctl") }
sub pp_msgsnd { listop(@_, "msgsnd") }
sub pp_msgrcv { listop(@_, "msgrcv") }
sub pp_semget { listop(@_, "semget") }
sub pp_semctl { listop(@_, "semctl") }
sub pp_semop { listop(@_, "semop") }
sub pp_ghbyaddr { listop(@_, "gethostbyaddr") }
sub pp_gnbyaddr { listop(@_, "getnetbyaddr") }
sub pp_gpbynumber { listop(@_, "getprotobynumber") }
sub pp_gsbyname { listop(@_, "getservbyname") }
sub pp_gsbyport { listop(@_, "getservbyport") }
sub pp_syscall { listop(@_, "syscall") }

sub pp_glob {
    my $self = shift;
    my $op = shift;
    my $text = $self->dq($op->first->sibling);  # skip pushmark
    if ($text =~ /^\$?(\w|::|\`)+$/ # could look like a readline
	or $text =~ /[<>]/) { 
	return 'glob(' . single_delim('qq', '"', $text) . ')';
    } else {
	return '<' . $text . '>';
    }
}

sub indirop {
    my $self = shift;
    my($op, $name) = (@_, 0);
    my($expr, @exprs);
    my $kid = $op->first->sibling;
    my $indir = "";
    if ($op->flags & OPf_STACKED) {
	$indir = $kid;
	$indir = $indir->first; # skip rv2gv
	if (is_scope($indir)) {
	    $indir = "{" . $self->deparse($indir) . "}";
	} else {
	    $indir = $self->deparse($indir);
	}
	$indir = $indir . " ";
	$kid = $kid->sibling;
    }
    for (; !null($kid); $kid = $kid->sibling) {
	$expr = $self->deparse($kid);
	push @exprs, $expr;
    }
    return "$name($indir" . join(", ", @exprs) . ")";
}

sub pp_prtf { indirop(@_, "printf") }
sub pp_print { indirop(@_, "print") }
sub pp_sort { indirop(@_, "sort") }

sub mapop {
    my $self = shift;
    my($op, $name) = @_;
    my($expr, @exprs);
    my $kid = $op->first; # this is the (map|grep)start
    $kid = $kid->first->sibling; # skip a pushmark
    my $code = $kid->first; # skip a null
    if (is_scope $code) {
	$code = "{" . $self->deparse($code) . "} ";
    } else {
	$code = $self->deparse($code) . ", ";
    }
    $kid = $kid->sibling;
    for (; !null($kid); $kid = $kid->sibling) {
	$expr = $self->deparse($kid);
	push @exprs, $expr if $expr;
    }
    return "$name($code" . join(", ", @exprs) . ")";
}

sub pp_mapwhile { mapop(@_, "map") }   
sub pp_grepwhile { mapop(@_, "grep") }   

sub pp_list {
    my $self = shift;
    my $op = shift;
    my($expr, @exprs);
    my $kid = $op->first->sibling; # skip pushmark
    my $lop;
    my $local = "either"; # could be local(...) or my(...)
    for ($lop = $kid; !null($lop); $lop = $lop->sibling) {
	# This assumes that no other private flags equal 128, and that
	# OPs that store things other than flags in their op_private,
	# like OP_AELEMFAST, won't be immediate children of a list.
	unless ($lop->private & OPp_LVAL_INTRO or $lop->ppaddr eq "pp_undef")
	{
	    $local = ""; # or not
	    last;
	}
	if ($lop->ppaddr =~ /^pp_pad[ash]v$/) { # my()
	    ($local = "", last) if $local eq "local";
	    $local = "my";
	} elsif ($lop->ppaddr ne "pp_undef") { # local()
	    ($local = "", last) if $local eq "my";
	    $local = "local";
	}
    }
    $local = "" if $local eq "either"; # no point if it's all undefs
    for (; !null($kid); $kid = $kid->sibling) {
	if ($local) {
	    if (class($kid) eq "UNOP" and $kid->first->ppaddr eq "pp_gvsv") {
		$lop = $kid->first;
	    } else {
		$lop = $kid;
	    }
	    $self->{'avoid_local'}{$$lop}++;
	    $expr = $self->deparse($kid);
	    delete $self->{'avoid_local'}{$$lop};
	} else {
	    $expr = $self->deparse($kid);
	}
	push @exprs, $expr;
    }
    return "$local(" . join(", ", @exprs) . ")";
}

sub pp_cond_expr {
    my $self = shift;
    my $op = shift;
    my $cond = $op->first;
    my $true = $cond->sibling;
    my $false = $true->sibling;
    my $braces = 0;
    $cond = $self->deparse($cond);
    $braces = 1 if is_scope($true) or is_scope($false);
    $true = $self->deparse($true);
    if ($false->ppaddr eq "pp_lineseq") { # braces w/o scope => elsif
	my $head = "if ($cond) {\n\t$true\n\b}";
	my @elsifs;
	while (!null($false) and $false->ppaddr eq "pp_lineseq") {
	    my $newop = $false->first->sibling->first;
	    my $newcond = $newop->first;
	    my $newtrue = $newcond->sibling;
	    $false = $newtrue->sibling; # last in chain is OP_AND => no else
	    $newcond = $self->deparse($newcond);
	    $newtrue = $self->deparse($newtrue);
	    push @elsifs, "elsif ($newcond) {\n\t$newtrue\n\b}";
	}
	if (!null($false)) {	    
	    $false = "\nelse {\n\t" . $self->deparse($false) . "\n\b}";
	} else {
	    $false = "";
	}
	return $head . join("\n", "", @elsifs) . $false; 
    }
    $false = $self->deparse($false);
    if ($braces) {
	return "if ($cond) {\n\t$true\n\b}\nelse {\n\t$false\n\b}";
    } else {
	return "($cond ? $true : $false)";
    }
}

sub pp_leaveloop {
    my $self = shift;
    my $op = shift;
    my $enter = $op->first;
    my $kid = $enter->sibling;
    local($self->{'curstash'}) = $self->{'curstash'};
    my $head = "";
    if ($kid->ppaddr eq "pp_lineseq") { # bare or infinite loop 
	if (is_state $kid->last) { # infinite
	    $head = "for (;;) "; # shorter than while (1)
	}
    } elsif ($enter->ppaddr eq "pp_enteriter") { # foreach
	my $ary = $enter->first->sibling; # first was pushmark
	my $var = $ary->sibling;
	$ary = $self->deparse($ary);
	if (null $var) {
	    $var = $self->pp_padsv($enter);
	    if ($self->padname_sv($enter->targ)->IVX ==
		$kid->first->first->sibling->last->cop_seq)
	    {
		# If the scope of this variable closes at the last
		# statement of the loop, it must have been declared here.
		$var = "my " . $var;
	    }
	} elsif ($var->ppaddr eq "pp_rv2gv") {
	    $var = $self->pp_rv2sv($var);
	} elsif ($var->ppaddr eq "pp_gv") {
	    $var = "\$" . $self->deparse($var);
	}
	$head = "foreach $var $ary ";
	$kid = $kid->first->first->sibling; # skip OP_AND and OP_ITER
    } elsif ($kid->ppaddr eq "pp_null") { # while/until
	$kid = $kid->first;
	my $name = {"pp_and" => "while", "pp_or" => "until"}
	            ->{$kid->ppaddr};
	$head = "$name (" . $self->deparse($kid->first) . ") ";
	$kid = $kid->first->sibling;
    }
    # The third-to-last kid is the continue block if the pointer used
    # by `next BLOCK' points to its nulled-out nextstate, which is its
    # first or second kid depending on whether the block was optimized
    # to a OP_SCOPE.
    my $cont = $kid;
    unless ($kid->ppaddr eq "pp_stub") { # empty bare loop
	$cont = $kid->first;
	unless (null $cont->sibling->sibling) {
	    while (!null($cont->sibling->sibling->sibling)) {
		$cont = $cont->sibling;
	    }
	}
    }
    if (is_scope($cont) 
	and $ {$enter->nextop} == $ {$cont->first}
	    || $ {$enter->nextop} == $ {$cont->first->sibling})
    {
	my $state = $kid->first;
	my($expr, @exprs);
	for (; $$state != $$cont; $state = $state->sibling) {
	    $expr = "";
	    if (is_state $state) {
		$expr = $self->deparse($state);
		$state = $state->sibling;
		last if null $kid;
	    }
	    $expr .= $self->deparse($state);
	    push @exprs, $expr if $expr;
	}
	$kid = join(";\n", @exprs);
	$cont = " continue {\n\t" . $self->deparse($cont) . "\n\b}\n";
    } else {
	$cont = "";
	$kid = $self->deparse($kid);
    }
    return $head . "{\n\t" . $kid . "\n\b}" . $cont;
}

sub pp_leavetry {
    my $self = shift;
    return "eval {\n\t" . $self->pp_leave($_[0]) . "\n\b}";
}

sub OP_CONST () { 5 }
sub OP_STRINGIFY () { 65 }

sub pp_null {
    my $self = shift;
    my $op = shift;
    if (class($op) eq "OP") {
	return "'???'" if $op->targ == OP_CONST; # old value is lost
    } elsif ($op->first->ppaddr eq "pp_pushmark") {
	return $self->pp_list($op);
    } elsif ($op->first->ppaddr eq "pp_enter") {
	return $self->pp_leave($op);
    } elsif ($op->targ == OP_STRINGIFY) {
	return $self->dquote($op);
    } elsif (!null($op->first->sibling) and
	     $op->first->sibling->ppaddr eq "pp_readline" and
	     $op->first->sibling->flags & OPf_STACKED) {
	return "(" . $self->deparse($op->first) . " = "
	    . $self->deparse($op->first->sibling) . ")";
    } elsif (!null($op->first->sibling) and
	     $op->first->sibling->ppaddr eq "pp_trans" and
	     $op->first->sibling->flags & OPf_STACKED) {
	return "(" . $self->deparse($op->first) . " =~ "
	    . $self->deparse($op->first->sibling) . ")";
    } else {
	return $self->deparse($op->first);
    }
}

sub padname {
    my $self = shift;
    my $targ = shift;
    my $str = $self->padname_sv($targ)->PV;
    return padname_fix($str);
}

sub padany {
    my $self = shift;
    my $op = shift;
    return substr($self->padname($op->targ), 1); # skip $/@/%
}

sub pp_padsv {
    my $self = shift;
    my $op = shift;
    return $self->maybe_my($op, $self->padname($op->targ));
}

sub pp_padav { pp_padsv(@_) }
sub pp_padhv { pp_padsv(@_) }

sub pp_gvsv {
    my $self = shift;
    my $op = shift;
    return $self->maybe_local($op, "\$" . $self->gv_name($op->gv));
}

sub pp_gv {
    my $self = shift;
    my $op = shift;
    return $self->gv_name($op->gv);
}

sub pp_aelemfast {
    my $self = shift;
    my $op = shift;
    my $gv = $op->gv;
    return "\$" . $self->gv_name($gv) . "[" . $op->private . "]";
}

sub rv2x {
    my $self = shift;
    my($op, $type) = @_;
    my $kid = $op->first;
    my $scope = is_scope($kid);
    $kid = $self->deparse($kid);
    return $type . ($scope ? "{$kid}" : $kid);
}

sub pp_rv2sv { maybe_local(@_, rv2x(@_, "\$")) }
sub pp_rv2hv { maybe_local(@_, rv2x(@_, "%")) }
sub pp_rv2gv { maybe_local(@_, rv2x(@_, "*")) }

# skip rv2av
sub pp_av2arylen {
    my $self = shift;
    my $op = shift;
    if ($op->first->ppaddr eq "pp_padav") {
	return $self->maybe_local($op, '$#' . $self->padany($op->first));
    } else {
	return $self->maybe_local($op, $self->rv2x($op->first, '$#'));
    }
}

# skip down to the old, ex-rv2cv
sub pp_rv2cv { $_[0]->rv2x($_[1]->first->first->sibling, "&") }

sub pp_rv2av {
    my $self = shift;
    my $op = shift;
    my $kid = $op->first;
    if ($kid->ppaddr eq "pp_const") { # constant list
	my $av = $kid->sv;
	return "(" . join(", ", map(const($_), $av->ARRAY)) . ")";
    } else {
	return $self->maybe_local($op, $self->rv2x($op, "\@"));
    }
 }


sub elem {
    my $self = shift;
    my ($op, $left, $right, $padname) = @_;
    my($array, $idx) = ($op->first, $op->first->sibling);
    unless ($array->ppaddr eq $padname) { # Maybe this has been fixed	
	$array = $array->first; # skip rv2av (or ex-rv2av in _53+)
    }
    if ($array->ppaddr eq $padname) {
	$array = $self->padany($array);
    } elsif (is_scope($array)) { # ${expr}[0]
	$array = "{" . $self->deparse($array) . "}";
    } elsif (is_scalar $array) { # $x[0], $$x[0], ...
	$array = $self->deparse($array);
    } else {
	# $x[20][3]{hi} or expr->[20]
	my $arrow;
	$arrow = "->" if $array->ppaddr !~ /^pp_[ah]elem$/;
	return $self->deparse($array) . $arrow .
	    $left . $self->deparse($idx) . $right;
    }
    $idx = $self->deparse($idx);
    return "\$" . $array . $left . $idx . $right;
}

sub pp_aelem { maybe_local(@_, elem(@_, "[", "]", "pp_padav")) }
sub pp_helem { maybe_local(@_, elem(@_, "{", "}", "pp_padhv")) }

sub pp_gelem {
    my $self = shift;
    my $op = shift;
    my($glob, $part) = ($op->first, $op->last);
    $glob = $glob->first; # skip rv2gv
    $glob = $glob->first if $glob->ppaddr eq "pp_rv2gv"; # this one's a bug
    my $scope = (is_scope($glob));
    $glob = $self->deparse($glob);
    $part = $self->deparse($part);
    return "*" . ($scope ? "{$glob}" : $glob) . "{$part}";
}

sub slice {
    my $self = shift;
    my ($op, $left, $right, $regname, $padname) = @_;
    my $last;
    my(@elems, $kid, $array, $list);
    if (class($op) eq "LISTOP") {
	$last = $op->last;
    } else { # ex-hslice inside delete()
	for ($kid = $op->first; !null $kid->sibling; $kid = $kid->sibling) {}
	$last = $kid;
    }
    $array = $last;
    $array = $array->first
	if $array->ppaddr eq $regname or $array->ppaddr eq "pp_null";
    if (is_scope($array)) {
	$array = "{" . $self->deparse($array) . "}";
    } elsif ($array->ppaddr eq $padname) {
	$array = $self->padany($array);
    } else {
	$array = $self->deparse($array);
    }
    $kid = $op->first->sibling; # skip pushmark
    if ($kid->ppaddr eq "pp_list") {
	$kid = $kid->first->sibling; # skip list, pushmark
	for (; !null $kid; $kid = $kid->sibling) {
	    push @elems, $self->deparse($kid);
	}
	$list = join(", ", @elems);
    } else {
	$list = $self->deparse($kid);
    }
    return "\@" . $array . $left . $list . $right;
}

sub pp_aslice { maybe_local(@_, slice(@_, "[", "]", 
				      "pp_rv2av", "pp_padav")) }
sub pp_hslice { maybe_local(@_, slice(@_, "{", "}",
				      "pp_rv2hv", "pp_padhv")) }

sub pp_lslice {
    my $self = shift;
    my $op = shift;
    my $idx = $op->first;
    my $list = $op->last;
    my(@elems, $kid);
    $list = $self->deparse($list); # will always have parens
    $idx = $self->deparse($idx);
    return $list . "[$idx]";
}

sub OPpENTERSUB_AMPER () { 8 }

sub OPf_WANT () { 3 }
sub OPf_WANT_VOID () { 1 }
sub OPf_WANT_SCALAR () { 2 }
sub OPf_WANT_LIST () { 2 }

sub want_scalar {
    my $op = shift;
    return ($op->flags & OPf_WANT) == OPf_WANT_SCALAR;
}

sub pp_entersub {
    my $self = shift;
    my $op = shift;
    my $prefix = "";
    my $amper = "";
    my $proto = undef;
    my($kid, $args, @exprs);
    if ($op->flags & OPf_SPECIAL) {
	$prefix = "do ";
    } elsif ($op->private & OPpENTERSUB_AMPER) {
	$amper = "&";
    }
    if (not null $op->first->sibling) {
	$kid = $op->first->sibling; # skip pushmark
	my $obj = $self->deparse($kid);
	$kid = $kid->sibling;
	for (; not null $kid->sibling; $kid = $kid->sibling) {
	    push @exprs, $self->deparse($kid);
	}
	my $meth = $kid->first;
	if ($meth->ppaddr eq "pp_const") {
	    $meth = $meth->sv->PV; # needs to be bare
	} else {
	    $meth = $self->deparse($meth);
	}
	$prefix = "";
	$args = join(", ", @exprs);	
	$kid = $obj . "->" . $meth;
    } else {
	$kid = $op->first;
	$kid = $kid->first->sibling; # skip ex-list, pushmark
	for (; not null $kid->sibling; $kid = $kid->sibling) {
	    push @exprs, $kid;
	}
	if (is_scope($kid)) {
	    $kid = "{" . $self->deparse($kid) . "}";
	} elsif ($kid->first->ppaddr eq "pp_gv") {
	    my $gv = $kid->first->gv;
	    if (class($gv->CV) ne "SPECIAL") {
		$proto = $gv->CV->PV if $gv->CV->FLAGS & SVf_POK;
	    }
	    $kid = $self->deparse($kid);
	} elsif (is_scalar $kid->first) {
	    $amper = "&";
	    $kid = $self->deparse($kid);
	} else {
	    $prefix = "";
	    $kid = $self->deparse($kid) . "->";
	}
	if (defined $proto and not $amper) {
	    my($arg, $real);
	    my $doneok = 0;
	    my @args = @exprs;
	    my @reals;
	    $proto =~ s/([^\\]|^)([@%])(.*)$/$1$2/;
	    while ($proto) {
		$proto =~ s/^ *([\\]?[\$\@&%*]|;)//;
		my $chr = $1;
		if ($chr eq "") {
		    undef $proto if @args;
		} elsif ($chr eq ";") {
		    $doneok = 1;
		} elsif ($chr eq "@" or $chr eq "%") {
		    push @reals, map($self->deparse($_), @args);
		    @args = ();
		} else {
		    $arg = shift @args;
		    undef $proto, last unless $arg;
		    if ($chr eq "\$") {
			if (want_scalar $arg) {
			    push @reals, $self->deparse($arg);
			} else {
			    undef $proto;
			}
		    } elsif ($chr eq "&") {
			if ($arg->ppaddr =~ /pp_(s?refgen|undef)/) {
			    push @reals, $self->deparse($arg);
			} else {
			    undef $proto;
			}
		    } elsif ($chr eq "*") {
			if ($arg->ppaddr =~ /^pp_s?refgen$/
			    and $arg->first->first->ppaddr eq "pp_rv2gv")
			{
			    $real = $arg->first->first; # skip refgen, null
			    if ($real->first->ppaddr eq "pp_gv") {
				push @reals, $self->deparse($real);
			    } else {
				push @reals, $self->deparse($real->first);
			    }
			} else {
			    undef $proto;
			}
		    } elsif (substr($chr, 0, 1) eq "\\") {
			$chr = substr($chr, 1);
			if ($arg->ppaddr =~ /^pp_s?refgen$/ and
			    !null($real = $arg->first) and
			    ($chr eq "\$" && is_scalar($real->first)
			     or ($chr eq "\@"
				 && $real->first->sibling->ppaddr 
				 =~ /^pp_(rv2|pad)av$/)
			     or ($chr eq "%"
				 && $real->first->sibling->ppaddr
				 =~ /^pp_(rv2|pad)hv$/)
			     #or ($chr eq "&" # This doesn't work
			     #   && $real->first->ppaddr eq "pp_rv2cv")
			     or ($chr eq "*"
				 && $real->first->ppaddr eq "pp_rv2gv")))
			{
			    push @reals, $self->deparse($real);
			} else {
			    undef $proto;
			}
		    }
		}
	    }
	    undef $proto if $proto and !$doneok;
	    undef $proto if @args;
	    $args = join(", ", @reals);
	    $amper = "";
	    unless (defined $proto) {
		$amper = "&";
		$args = join(", ", map($self->deparse($_), @exprs));
	    }
	} else {
	    $args = join(", ", map($self->deparse($_), @exprs));
	}
    }
    if ($op->flags & OPf_STACKED) {
	return $prefix . $amper . $kid . "(" . $args . ")";
    } else {
	return $prefix . $amper. $kid;
    }
}

sub pp_enterwrite { unop(@_, "write") }

# escape things that cause interpolation in double quotes,
# but not character escapes
sub uninterp {
    my($str) = @_;
    $str =~ s/(^|[^\\])([\$\@]|\\[uUlLQE])/$1\\$2/;
    return $str;
}

# character escapes, but not delimiters that might need to be escaped
sub escape_str { # ASCII
    my($str) = @_;
    $str =~ s/\\/\\\\/g;
    $str =~ s/\a/\\a/g;
#    $str =~ s/\cH/\\b/g; # \b means someting different in a regex 
    $str =~ s/\t/\\t/g;
    $str =~ s/\n/\\n/g;
    $str =~ s/\e/\\e/g;
    $str =~ s/\f/\\f/g;
    $str =~ s/\r/\\r/g;
    $str =~ s/([\cA-\cZ])/'\\c' . chr(ord('@') + ord($1))/ge;
    $str =~ s/([\0\033-\037\177-\377])/'\\' . sprintf("%03o", ord($1))/ge;
    return $str;
}

sub balanced_delim {
    my($str) = @_;
    my @str = split //, $str;
    my($ar, $open, $close, $fail, $c, $cnt);
    for $ar (['[',']'], ['(',')'], ['<','>'], ['{','}']) {
	($open, $close) = @$ar;
	$fail = 0; $cnt = 0;
	for $c (@str) {
	    if ($c eq $open) {
		$cnt++;
	    } elsif ($c eq $close) {
		$cnt--;
		if ($cnt < 0) {
		    $fail = 1;
		    last;
		}
	    }
	}
	$fail = 1 if $cnt != 0;
	return ($open, "$open$str$close") if not $fail;
    }
    return ("", $str);
}

sub single_delim {
    my($q, $default, $str) = @_;
    return "$default$str$default" if index($str, $default) == -1;
    my($succeed, $delim);
    ($succeed, $str) = balanced_delim($str);
    return "$q$str" if $succeed;
    for $delim ('/', '"', '#') {
	return "$q$delim" . $str . $delim if index($str, $delim) == -1;
    }
    $str =~ s/$default/\\$default/g;
    return "$default$str$default";
}

sub SVf_IOK () {0x10000}
sub SVf_NOK () {0x20000}
sub SVf_ROK () {0x80000}

sub const {
    my $sv = shift;
    if (class($sv) eq "SPECIAL") {
	return ('undef', '1', '+0')[$$sv-1];
    } elsif ($sv->FLAGS & SVf_IOK) {
	return $sv->IV;
    } elsif ($sv->FLAGS & SVf_NOK) {
	return "0.0" unless $sv->NV;
	return $sv->NV;
    } elsif ($sv->FLAGS & SVf_ROK) {
	return "\\(" . const($sv->RV) . ")"; # constant folded
    } else {
	my $str = $sv->PV;
	if ($str =~ /[^ -~]/) { # ASCII
	    return single_delim("qq", '"', uninterp(escape_str($str)));
	} else {
	    $str =~ s/\\/\\\\/g;
	    return single_delim("q", "'", $str);
	}
    }
}

sub pp_const {
    my $self = shift;
    my $op = shift;
#    if ($op->private & OPp_CONST_BARE) { # trouble with `=>' autoquoting 
#	return $op->sv->PV;
#    }
    return const($op->sv);
}

sub dq {
    my $self = shift;
    my $op = shift;
    my $type = $op->ppaddr;
    if ($type eq "pp_const") {
	return uninterp(escape_str($op->sv->PV));
    } elsif ($type eq "pp_concat") {
	return $self->dq($op->first) . $self->dq($op->last);
    } elsif ($type eq "pp_uc") {
	return '\U' . $self->dq($op->first->sibling) . '\E';
    } elsif ($type eq "pp_lc") {
	return '\L' . $self->dq($op->first->sibling) . '\E';
    } elsif ($type eq "pp_ucfirst") {
	return '\u' . $self->dq($op->first->sibling);
    } elsif ($type eq "pp_lcfirst") {
	return '\l' . $self->dq($op->first->sibling);
    } elsif ($type eq "pp_quotemeta") {
	return '\Q' . $self->dq($op->first->sibling) . '\E';
    } elsif ($type eq "pp_join") {
	return $self->deparse($op->last); # was join($", @ary)
    } else {
	return $self->deparse($op);
    }
}

sub pp_backtick {
    my $self = shift;
    my $op = shift;
    # skip pushmark
    return single_delim("qx", '`', $self->dq($op->first->sibling));
}

sub dquote {
    my $self = shift;
    my $op = shift;
    # skip ex-stringify, pushmark
    return single_delim("qq", '"', $self->dq($op->first->sibling)); 
}

# OP_STRINGIFY is a listop, but it only ever has one arg (?)
sub pp_stringify { dquote(@_) }

# tr/// and s/// (and tr[][], tr[]//, tr###, etc)
# note that tr(from)/to/ is OK, but not tr/from/(to)
sub double_delim {
    my($from, $to) = @_;
    my($succeed, $delim);
    if ($from !~ m[/] and $to !~ m[/]) {
	return "/$from/$to/";
    } elsif (($succeed, $from) = balanced_delim($from) and $succeed) {
	if (($succeed, $to) = balanced_delim($to) and $succeed) {
	    return "$from$to";
	} else {
	    for $delim ('/', '"', '#') { # note no `'' -- s''' is special
		return "$from$delim$to$delim" if index($to, $delim) == -1;
	    }
	    $to =~ s[/][\\/]g;
	    return "$from/$to/";
	}
    } else {
	for $delim ('/', '"', '#') { # note no '
	    return "$delim$from$delim$to$delim"
		if index($to . $from, $delim) == -1;
	}
	$from =~ s[/][\\/]g;
	$to =~ s[/][\\/]g;
	return "/$from/$to/";	
    }
}

sub pchr { # ASCII
    my($n) = @_;
    if ($n == ord '\\') {
	return '\\\\';
    } elsif ($n >= ord(' ') and $n <= ord('~')) {
	return chr($n);
    } elsif ($n == ord "\a") {
	return '\\a';
    } elsif ($n == ord "\b") {
	return '\\b';
    } elsif ($n == ord "\t") {
	return '\\t';
    } elsif ($n == ord "\n") {
	return '\\n';
    } elsif ($n == ord "\e") {
	return '\\e';
    } elsif ($n == ord "\f") {
	return '\\f';
    } elsif ($n == ord "\r") {
	return '\\r';
    } elsif ($n >= ord("\cA") and $n <= ord("\cZ")) {
	return '\\c' . chr(ord("@") + $n);
    } else {
#	return '\x' . sprintf("%02x", $n);
	return '\\' . sprintf("%03o", $n);
    }
}

sub collapse {
    my(@chars) = @_;
    my($c, $str, $tr);
    for ($c = 0; $c < @chars; $c++) {
	$tr = $chars[$c];
	$str .= pchr($tr);
	if ($c <= $#chars - 2 and $chars[$c + 1] == $tr + 1 and
	    $chars[$c + 2] == $tr + 2)
	{
	    for (; $c <= $#chars and $chars[$c + 1] == $chars[$c] + 1; $c++) {}
	    $str .= "-";
	    $str .= pchr($chars[$c]);
	}
    }
    return $str;
}

sub OPpTRANS_SQUASH () { 16 }
sub OPpTRANS_DELETE () { 32 }
sub OPpTRANS_COMPLEMENT () { 64 }

sub pp_trans {
    my $self = shift;
    my $op = shift;
    my(@table) = unpack("s256", $op->pv);
    my($c, $tr, @from, @to, @delfrom, $delhyphen);
    if ($table[ord "-"] != -1 and 
	$table[ord("-") - 1] == -1 || $table[ord("-") + 1] == -1)
    {
	$tr = $table[ord "-"];
	$table[ord "-"] = -1;
	if ($tr >= 0) {
	    @from = ord("-");
	    @to = $tr;
	} else { # -2 ==> delete
	    $delhyphen = 1;
	}
    }
    for ($c = 0; $c < 256; $c++) {
	$tr = $table[$c];
	if ($tr >= 0) {
	    push @from, $c; push @to, $tr;
	} elsif ($tr == -2) {
	    push @delfrom, $c;
	}
    }
    my $flags;
    @from = (@from, @delfrom);
    if ($op->private & OPpTRANS_COMPLEMENT) {
	$flags .= "c";
	my @newfrom = ();
	my %from;
	@from{@from} = (1) x @from;
	for ($c = 0; $c < 256; $c++) {
	    push @newfrom, $c unless $from{$c};
	}
	@from = @newfrom;
    }
    if ($op->private & OPpTRANS_DELETE) {
	$flags .= "d";
    } else {
	pop @to while $#to and $to[$#to] == $to[$#to -1];
    }
    $flags .= "s" if $op->private & OPpTRANS_SQUASH;
    my($from, $to);
    $from = collapse(@from);
    $to = collapse(@to);
    $from .= "-" if $delhyphen;
    return "tr" . double_delim($from, $to) . $flags;
}

# Like dq(), but different
sub re_dq {
    my $self = shift;
    my $op = shift;
    my $type = $op->ppaddr;
    if ($type eq "pp_const") {
	return uninterp($op->sv->PV);
    } elsif ($type eq "pp_concat") {
	return $self->re_dq($op->first) . $self->re_dq($op->last);
    } elsif ($type eq "pp_uc") {
	return '\U' . $self->re_dq($op->first->sibling) . '\E';
    } elsif ($type eq "pp_lc") {
	return '\L' . $self->re_dq($op->first->sibling) . '\E';
    } elsif ($type eq "pp_ucfirst") {
	return '\u' . $self->re_dq($op->first->sibling);
    } elsif ($type eq "pp_lcfirst") {
	return '\l' . $self->re_dq($op->first->sibling);
    } elsif ($type eq "pp_quotemeta") {
	return '\Q' . $self->re_dq($op->first->sibling) . '\E';
    } elsif ($type eq "pp_join") {
	return $self->deparse($op->last); # was join($", @ary)
    } else {
	return $self->deparse($op);
    }
}

sub pp_regcomp {
    my $self = shift;
    my $op = shift;
    my $kid = $op->first;
    $kid = $kid->first if $kid->ppaddr eq "pp_regcmaybe";
    return $self->re_dq($kid);
}

sub OPp_RUNTIME () { 64 }

sub PMf_ONCE () { 0x2 }
sub PMf_SKIPWHITE () { 0x10 }
sub PMf_FOLD () { 0x20 }
sub PMf_CONST () { 0x40 }
sub PMf_KEEP () { 0x80 }
sub PMf_GLOBAL () { 0x100 }
sub PMf_CONTINUE () { 0x200 }
sub PMf_EVAL () { 0x400 }
sub PMf_MULTILINE () { 0x1000 }
sub PMf_SINGLELINE () { 0x2000 }
sub PMf_LOCALE () { 0x4000 }
sub PMf_EXTENDED () { 0x8000 }

# osmic acid -- see osmium tetroxide

my %matchwords;
map($matchwords{join "", sort split //, $_} = $_, 'cig', 'cog', 'cos', 'cogs',
    'cox', 'go', 'is', 'ism', 'iso', 'mig', 'mix', 'osmic', 'ox', 'sic', 
    'sig', 'six', 'smog', 'so', 'soc', 'sog', 'xi'); 

sub pp_match {
    my $self = shift;
    my $op = shift;
    my $kid = $op->first;
    my ($pre, $post, $re) = ("", "", "");
    if ($op->flags & OPf_STACKED) {
	$pre = "(" . $self->deparse($kid) . " =~ ";
	$post = ")";
	$kid = $kid->sibling;
    }
    if (null $kid) {
	$re = uninterp(escape_str($op->precomp));
    } else {
	$re = $self->deparse($kid);
    }
    my $flags = "";
    $flags .= "c" if $op->pmflags & PMf_CONTINUE;
    $flags .= "g" if $op->pmflags & PMf_GLOBAL;
    $flags .= "i" if $op->pmflags & PMf_FOLD;
    $flags .= "m" if $op->pmflags & PMf_MULTILINE;
    $flags .= "o" if $op->pmflags & PMf_KEEP;
    $flags .= "s" if $op->pmflags & PMf_SINGLELINE;
    $flags .= "x" if $op->pmflags & PMf_EXTENDED;
    $flags = $matchwords{$flags} if $matchwords{$flags};
    if ($op->pmflags & PMf_ONCE) { # only one kind of delimiter works here
	$re =~ s/\?/\\?/g;
	return "$pre?$re?$flags$post";
    }
    return $pre . single_delim("m", "/", $re) . "$flags$post";
}

sub pp_pushre { pp_match(@_) }

sub pp_split {
    my $self = shift;
    my $op = shift;
    my($kid, @exprs, $ary, $expr);
    $kid = $op->first;
    if ($ {$kid->pmreplroot}) {
	$ary = '@' . $self->gv_name($kid->pmreplroot);
    }
    for (; !null($kid); $kid = $kid->sibling) {
	push @exprs, $self->deparse($kid);
    }
    $expr = "split(" . join(", ", @exprs) . ")";
    if ($ary) {
	return "(" . $ary . " = " . $expr . ")";
    } else {
	return $expr;
    }
}

# oxime -- any of various compounds obtained chiefly by the action of
# hydroxylamine on aldehydes and ketones and characterized by the
# bivalent grouping C=NOH [Webster's Tenth]

my %substwords;
map($substwords{join "", sort split //, $_} = $_, 'ego', 'egoism', 'em',
    'es', 'ex', 'exes', 'gee', 'go', 'goes', 'ie', 'ism', 'iso', 'me',
    'meese', 'meso', 'mig', 'mix', 'os', 'ox', 'oxime', 'see', 'seem',
    'seg', 'sex', 'sig', 'six', 'smog', 'sog', 'some', 'xi');

sub pp_subst {
    my $self = shift;
    my $op = shift;
    my $kid = $op->first;
    my($pre, $post, $re, $repl) = ("", "", "", "");
    if ($op->flags & OPf_STACKED) {
	$pre = "(" . $self->deparse($kid) . " =~ ";
	$post = ")";
	$kid = $kid->sibling;
    }
    my $flags = "";    
    if (null($op->pmreplroot)) {
	$repl = $self->dq($kid);
	$kid = $kid->sibling;
    } else {
	$repl = $op->pmreplroot->first; # skip substcont
	while ($repl->ppaddr eq "pp_entereval") {
	    $repl = $repl->first;
	    $flags .= "e";
	}
	$repl = $self->deparse($repl);
    }
    if (null $kid) {
	$re = uninterp(escape_str($op->precomp));
    } else {
	$re = $self->deparse($kid);
    }
    $flags .= "e" if $op->pmflags & PMf_EVAL;
    $flags .= "g" if $op->pmflags & PMf_GLOBAL;
    $flags .= "i" if $op->pmflags & PMf_FOLD;
    $flags .= "m" if $op->pmflags & PMf_MULTILINE;
    $flags .= "o" if $op->pmflags & PMf_KEEP;
    $flags .= "s" if $op->pmflags & PMf_SINGLELINE;
    $flags .= "x" if $op->pmflags & PMf_EXTENDED;
    $flags = $substwords{$flags} if $substwords{$flags};
    return $pre . "s". double_delim($re, $repl) . "$flags$post";
}

1;
