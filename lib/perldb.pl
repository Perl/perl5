package DB;

$header = '$Header: perldb.pl,v 3.0.1.1 89/10/26 23:14:02 lwall Locked $';
#
# This file is automatically included if you do perl -d.
# It's probably not useful to include this yourself.
#
# Perl supplies the values for @line and %sub.  It effectively inserts
# a do DB'DB(<linenum>); in front of every place that can
# have a breakpoint.  It also inserts a do 'perldb.pl' before the first line.
#
# $Log:	perldb.pl,v $
# Revision 3.0.1.1  89/10/26  23:14:02  lwall
# patch1: RCS expanded an unintended $Header in lib/perldb.pl
# 
# Revision 3.0  89/10/18  15:19:46  lwall
# 3.0 baseline
# 
# Revision 2.0  88/06/05  00:09:45  root
# Baseline version 2.0.
# 
#

open(IN,"/dev/tty");		# so we don't dingle stdin
open(OUT,">/dev/tty");	# so we don't dongle stdout
select(OUT);
$| = 1;				# for DB'OUT
select(STDOUT);
$| = 1;				# for real STDOUT

$header =~ s/.Header: ([^,]+),v(\s+\S+\s+\S+).*$/$1$2/;
print OUT "\nLoading DB from $header\n\n";

sub DB {
    local($. ,$@, $!, $[, $,, $/, $\);
    $[ = 0; $, = ""; $/ = "\n"; $\ = "";
    ($line) = @_;
    if ($stop[$line]) {
	if ($stop eq '1') {
	    $signal |= 1;
	}
	else {
	    package main;
	    $DB'signal |= eval $DB'stop[$DB'line];  print DB'OUT $@;
	    $DB'stop[$DB'line] =~ s/;9$//;
	}
    }
    if ($single || $trace || $signal) {
	print OUT "$sub($line):\t",$line[$line];
	for ($i = $line + 1; $i <= $max && $line[$i] == 0; ++$i) {
	    last if $line[$i] =~ /^\s*(}|#|\n)/;
	    print OUT "$sub($i):\t",$line[$i];
	}
    }
    if ($action[$line]) {
	package main;
	eval $DB'action[$DB'line];  print DB'OUT $@;
    }
    if ($single || $signal) {
	if ($pre) {
	    package main;
	    eval $DB'pre;  print DB'OUT $@;
	}
	print OUT $#stack . " levels deep in subroutine calls!\n"
	    if $single & 4;
	$start = $line;
	while ((print OUT "  DB<", $#hist+1, "> "), $cmd=<IN>) {
	    $single = 0;
	    $signal = 0;
	    $cmd eq '' && exit 0;
	    chop($cmd);
	    $cmd =~ /^q$/ && exit 0;
	    $cmd =~ /^$/ && ($cmd = $laststep);
	    push(@hist,$cmd) if length($cmd) > 1;
	    ($i) = split(/\s+/,$cmd);
	    eval "\$cmd =~ $alias{$i}", print OUT $@ if $alias{$i};
	    $cmd =~ /^h$/ && do {
		print OUT "
T		Stack trace.
s		Single step.
n		Next, steps over subroutine calls.
f		Finish current subroutine.
c [line]	Continue; optionally inserts a one-time-only breakpoint 
		at the specified line.
<CR>		Repeat last n or s.
l min+incr	List incr+1 lines starting at min.
l min-max	List lines.
l line		List line;
l		List next window.
-		List previous window.
w line		List window around line.
l subname	List subroutine.
/pattern/	Search forwards for pattern; final / is optional.
?pattern?	Search backwards for pattern.
L		List breakpoints and actions.
S		List subroutine names.
t		Toggle trace mode.
b [line] [condition]
		Set breakpoint; line defaults to the current execution line; 
		condition breaks if it evaluates to true, defaults to \'1\'.
b subname [condition]
		Set breakpoint at first line of subroutine.
d [line]	Delete breakpoint.
D		Delete all breakpoints.
a [line] command
		Set an action to be done before the line is executed.
		Sequence is: check for breakpoint, print line if necessary,
		do action, prompt user if breakpoint or step, evaluate line.
A		Delete all actions.
V package	List all variables and values in package (default main).
< command	Define command before prompt.
> command	Define command after prompt.
! number	Redo command (default previous command).
! -number	Redo number\'th to last command.
H -number	Display last number commands (default all).
q or ^D		Quit.
p expr		Same as \"package main; print DB'OUT expr\".
command		Execute as a perl statement.

";
		next; };
	    $cmd =~ /^t$/ && do {
		$trace = !$trace;
		print OUT "Trace = ".($trace?"on":"off")."\n";
		next; };
	    $cmd =~ /^S$/ && do {
		foreach $subname (sort(keys %sub)) {
		    if ($subname =~ /^main'(.*)/) {
			print OUT $1,"\n";
		    }
		    else {
			print OUT $subname,"\n";
		    }
		}
		next; };
	    $cmd =~ /^V$/ && do {
		$cmd = 'V main'; };
	    $cmd =~ /^V\s*(['A-Za-z_]['\w]*)$/ && do {
		$packname = $1;
		do 'dumpvar.pl' unless defined &main'dumpvar;
		if (defined &main'dumpvar) {
		    &main'dumpvar($packname);
		}
		else {
		    print DB'OUT "dumpvar.pl not available.\n";
		}
		next; };
	    $cmd =~ /^l\s*(['A-Za-z_]['\w]*)/ && do {
		$subname = $1;
		$subname = "main'" . $subname unless $subname =~ /'/;
		$subrange = $sub{$subname};
		if ($subrange) {
		    if (eval($subrange) < -$window) {
			$subrange =~ s/-.*/+/;
		    }
		    $cmd = "l $subrange";
		} else {
		    print OUT "Subroutine $1 not found.\n";
		    next;
		} };
	    $cmd =~ /^w\s*(\d*)$/ && do {
		$incr = $window - 1;
		$start = $1 if $1;
		$start -= $preview;
		$cmd = 'l ' . $start . '-' . ($start + $incr); };
	    $cmd =~ /^-$/ && do {
		$incr = $window - 1;
		$cmd = 'l ' . ($start-$window*2) . '+'; };
	    $cmd =~ /^l$/ && do {
		$incr = $window - 1;
		$cmd = 'l ' . $start . '-' . ($start + $incr); };
	    $cmd =~ /^l\s*(\d*)\+(\d*)$/ && do {
		$start = $1 if $1;
		$incr = $2;
		$incr = $window - 1 unless $incr;
		$cmd = 'l ' . $start . '-' . ($start + $incr); };
	    $cmd =~ /^l\s*(([\d\$\.]+)([-,]([\d\$\.]+))?)?/ && do {
		$end = (!$2) ? $max : ($4 ? $4 : $2);
		$end = $max if $end > $max;
		$i = $2;
		$i = $line if $i eq '.';
		$i = 1 if $i < 1;
		for (; $i <= $end; $i++) {
		    print OUT "$i:\t", $line[$i];
		    last if $signal;
		}
		$start = $i;	# remember in case they want more
		$start = $max if $start > $max;
		next; };
	    $cmd =~ /^D$/ && do {
		print OUT "Deleting all breakpoints...\n";
		for ($i = 1; $i <= $max ; $i++) {
		    $stop[$i] = 0;
		}
		next; };
	    $cmd =~ /^L$/ && do {
		for ($i = 1; $i <= $max; $i++) {
		    if ($stop[$i] || $action[$i]) {
			print OUT "$i:\t", $line[$i];
			print OUT "  break if (", $stop[$i], ")\n" 
			    if $stop[$i];
			print OUT "  action:  ", $action[$i], "\n" 
			    if $action[$i];
			last if $signal;
		    }
		}
		next; };
	    $cmd =~ /^b\s*(['A-Za-z_]['\w]*)\s*(.*)/ && do {
		$subname = $1;
		$subname = "main'" . $subname unless $subname =~ /'/;
		($i) = split(/-/, $sub{$subname});
		if ($i) {
		    ++$i while $line[$i] == 0 && $i < $#line;
		    $stop[$i] = $2 ? $2 : 1;
		} else {
		    print OUT "Subroutine $1 not found.\n";
		}
		next; };
	    $cmd =~ /^b\s*(\d*)\s*(.*)/ && do {
		$i = ($1?$1:$line);
		if ($line[$i] == 0) {
		    print OUT "Line $i not breakable.\n";
		} else {
		    $stop[$i] = $2 ? $2 : 1;
		}
		next; };
	    $cmd =~ /^d\s*(\d+)?/ && do {
		$i = ($1?$1:$line);
		$stop[$i] = '';
		next; };
	    $cmd =~ /^A$/ && do {
		for ($i = 1; $i <= $max ; $i++) {
		    $action[$i] = '';
		}
		next; };
	    $cmd =~ /^<\s*(.*)/ && do {
		$pre = do action($1);
		next; };
	    $cmd =~ /^>\s*(.*)/ && do {
		$post = do action($1);
		next; };
	    $cmd =~ /^a\s*(\d+)(\s+(.*))?/ && do {
		$i = $1;
		if ($line[$i] == 0) {
		    print OUT "Line $i may not have an action.\n";
		} else {
		    $action[$i] = do action($3);
		}
		next; };
	    $cmd =~ /^n$/ && do {
		$single = 2;
		$laststep = $cmd;
		last; };
	    $cmd =~ /^s$/ && do {
		$single = 1;
		$laststep = $cmd;
		last; };
	    $cmd =~ /^c\s*(\d*)\s*$/ && do {
		$i = $1;
		if ($i) {
		    if ($line[$i] == 0) {
		        print OUT "Line $i not breakable.\n";
			next;
		    }
		    $stop[$i] .= ";9";	# add one-time-only b.p.
		}
		for ($i=0; $i <= $#stack; ) {
		    $stack[$i++] &= ~1;
		}
		last; };
	    $cmd =~ /^f$/ && do {
		$stack[$#stack] |= 2;
		last; };
	    $cmd =~ /^T$/ && do {
		for ($i=0; $i <= $#sub; ) {
		    print OUT $sub[$i++], "\n";
		    last if $signal;
		}
	        next; };
	    $cmd =~ /^\/(.*)$/ && do {
		$inpat = $1;
		$inpat =~ s:([^\\])/$:$1:;
		if ($inpat ne "") {
		    eval '$inpat =~ m'."\n$inpat\n";	
		    if ($@ ne "") {
		    	print OUT "$@";
		    	next;
		    }
		    $pat = $inpat;
		}
		$end = $start;
		eval '
		for (;;) {
		    ++$start;
		    $start = 1 if ($start > $max);
		    last if ($start == $end);
		    if ($line[$start] =~ m'."\n$pat\n".'i) {
			print OUT "$start:\t", $line[$start], "\n";
			last;
		    }
		} ';
		print OUT "/$pat/: not found\n" if ($start == $end);
		next; };
	    $cmd =~ /^\?(.*)$/ && do {
		$inpat = $1;
		$inpat =~ s:([^\\])\?$:$1:;
		if ($inpat ne "") {
		    eval '$inpat =~ m'."\n$inpat\n";	
		    if ($@ ne "") {
		    	print OUT "$@";
		    	next;
		    }
		    $pat = $inpat;
		}
		$end = $start;
		eval '
		for (;;) {
		    --$start;
		    $start = $max if ($start <= 0);
		    last if ($start == $end);
		    if ($line[$start] =~ m'."\n$pat\n".'i) {
			print OUT "$start:\t", $line[$start], "\n";
			last;
		    }
		} ';
		print OUT "?$pat?: not found\n" if ($start == $end);
		next; };
	    $cmd =~ /^!+\s*(-)?(\d+)?$/ && do {
		pop(@hist) if length($cmd) > 1;
		$i = ($1?($#hist-($2?$2:1)):($2?$2:$#hist));
		$cmd = $hist[$i] . "\n";
		print OUT $cmd;
		redo; };
	    $cmd =~ /^!(.+)$/ && do {
		$pat = "^$1";
		pop(@hist) if length($cmd) > 1;
		for ($i = $#hist; $i; --$i) {
		    last if $hist[$i] =~ $pat;
		}
		if (!$i) {
		    print OUT "No such command!\n\n";
		    next;
		}
		$cmd = $hist[$i] . "\n";
		print OUT $cmd;
		redo; };
	    $cmd =~ /^H\s*(-(\d+))?/ && do {
		$end = $2?($#hist-$2):0;
		$hist = 0 if $hist < 0;
		for ($i=$#hist; $i>$end; $i--) {
		    print OUT "$i: ",$hist[$i],"\n"
			unless $hist[$i] =~ /^.?$/;
		};
		next; };
	    $cmd =~ s/^p( .*)?$/print DB'OUT$1/;
	    {
		package main;
		eval $DB'cmd;
	    }
	    print OUT $@,"\n";
	}
	if ($post) {
	    package main;
	    eval $DB'post;  print DB'OUT $@;
	}
    }
}

sub action {
    local($action) = @_;
    while ($action =~ s/\\$//) {
	print OUT "+ ";
	$action .= <IN>;
    }
    $action;
}

sub catch {
    $signal = 1;
}

sub sub {
    push(@stack, $single);
    $single &= 1;
    $single |= 4 if $#stack == $deep;
    local(@args) = @_;
    for (@args) {
	if (/^Stab/ && length($_) == length($_main{'_main'})) {
	    $_ = sprintf("%s",$_);
	    print "ARG: $_\n";
	}
	else {
	    s/'/\\'/g;
	    s/(.*)/'$1'/ unless /^-?[\d.]+$/;
	}
    }
    push(@sub, $sub . '(' . join(', ', @args) . ') from ' . $line);
    if (wantarray) {
	@i = &$sub;
    }
    else {
	$i = &$sub;
	@i = $i;
    }
    --$#sub;
    $single |= pop(@stack);
    @i;
}

$single = 1;			# so it stops on first executable statement
$max = $#line;
@hist = ('?');
$SIG{'INT'} = "DB'catch";
$deep = 100;		# warning if stack gets this deep
$window = 10;
$preview = 3;

@stack = (0);
@args = @ARGV;
for (@args) {
    s/'/\\'/g;
    s/(.*)/'$1'/ unless /^-?[\d.]+$/;
}
push(@sub, 'main(' . join(', ', @args) . ")" );
$sub = 'main';

if (-f '.perldb') {
    do './.perldb';
}
elsif (-f "$ENV{'LOGDIR'}/.perldb") {
    do "$ENV{'LOGDIR'}/.perldb";
}
elsif (-f "$ENV{'HOME'}/.perldb") {
    do "$ENV{'HOME'}/.perldb";
}

1;
