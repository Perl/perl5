package DB;

# modified Perl debugger, to be run from Emacs in perldb-mode
# Ray Lischner (uunet!mntgfx!lisch) as of 5 Nov 1990
# Johan Vromans -- upgrade to 4.0 pl 10

$header = '$RCSfile: perl5db.pl,v $$Revision: 4.1 $$Date: 92/08/07 18:24:07 $';
#
# This file is automatically included if you do perl -d.
# It's probably not useful to include this yourself.
#
# Perl supplies the values for @line and %sub.  It effectively inserts
# a &DB'DB(<linenum>); in front of every place that can
# have a breakpoint.  It also inserts a do 'perldb.pl' before the first line.
#
# $Log:	perldb.pl,v $

# Is Perl being run from Emacs?
$emacs = ((defined $main::ARGV[0]) and ($main::ARGV[0] eq '-emacs'));
shift(@main::ARGV) if $emacs;

#require Term::ReadLine;

local($^W) = 0;

if (-e "/dev/tty") {
    $console = "/dev/tty";
    $rcfile=".perldb";
}
elsif (-e "con") {
    $console = "con";
    $rcfile="perldb.ini";
}
else {
    $console = "sys\$command";
    $rcfile="perldb.ini";
}

# Around a bug:
if (defined $ENV{'OS2_SHELL'}) { # In OS/2
  if ($DB::emacs) {
    $console = undef;
  } else {
    $console = "/dev/con";
  }
}

open(IN, "<$console") || open(IN,  "<&STDIN");	# so we don't dingle stdin
open(OUT,">$console") || open(OUT, ">&STDERR")
    || open(OUT, ">&STDOUT");	# so we don't dongle stdout
select(OUT);
$| = 1;				# for DB::OUT
select(STDOUT);
$| = 1;				# for real STDOUT
$sub = '';

$header =~ s/.Header: ([^,]+),v(\s+\S+\s+\S+).*$/$1$2/;
print OUT "\nLoading DB routines from $header\n";
print OUT ("Emacs support ",
	   $emacs ? "enabled" : "available",
	   ".\n");
print OUT "\nEnter h for help.\n\n";

@ARGS;

sub DB {
    &save;
    ($pkg, $filename, $line) = caller;
    $usercontext = '($@, $!, $,, $/, $\, $^W) = @saved;' .
	"package $pkg;";		# this won't let them modify, alas
    local(*dbline) = "::_<$filename";
    $max = $#dbline;
    if (($stop,$action) = split(/\0/,$dbline{$line})) {
	if ($stop eq '1') {
	    $signal |= 1;
	}
	else {
	    $evalarg = "\$DB::signal |= do {$stop;}"; &eval;
	    $dbline{$line} =~ s/;9($|\0)/$1/;
	}
    }
    if ($single || $trace || $signal) {
	if ($emacs) {
	    print OUT "\032\032$filename:$line:0\n";
	} else {
	    $prefix = $sub =~ /'|::/ ? "" : "${pkg}::";
	    $prefix .= "$sub($filename:";
	    if (length($prefix) > 30) {
		print OUT "$prefix$line):\n$line:\t",$dbline[$line];
		$prefix = "";
		$infix = ":\t";
	    }
	    else {
		$infix = "):\t";
		print OUT "$prefix$line$infix",$dbline[$line];
	    }
	    for ($i = $line + 1; $i <= $max && $dbline[$i] == 0; ++$i) {
		last if $dbline[$i] =~ /^\s*(}|#|\n)/;
		print OUT "$prefix$i$infix",$dbline[$i];
	    }
	}
    }
    $evalarg = $action, &eval if $action;
    if ($single || $signal) {
	$evalarg = $pre, &eval if $pre;
	print OUT $#stack . " levels deep in subroutine calls!\n"
	    if $single & 4;
	$start = $line;
      CMD:
	while ((print OUT "  DB<", $#hist+1, "> "), $cmd=&gets) {
	    {
		$single = 0;
		$signal = 0;
		$cmd eq '' && exit 0;
		chop($cmd);
		$cmd =~ s/\\$// && do {
		    print OUT "  cont: ";
		    $cmd .= &gets;
		    redo CMD;
		};
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
r		Return from current subroutine.
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
f filename	Switch to filename.
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
V [pkg [vars]]	List some (default all) variables in package (default current).
X [vars]	Same as \"V currentpackage [vars]\".
< command	Define command before prompt.
> command	Define command after prompt.
! number	Redo command (default previous command).
! -number	Redo number\'th to last command.
H -number	Display last number commands (default all).
q or ^D		Quit.
p expr		Same as \"print DB::OUT expr\" in current package.
= [alias value]	Define a command alias, or list current aliases.
command		Execute as a perl statement in current package.

";
		    next CMD; };
		$cmd =~ /^t$/ && do {
		    $trace = !$trace;
		    print OUT "Trace = ".($trace?"on":"off")."\n";
		    next CMD; };
		$cmd =~ /^S$/ && do {
		    foreach $subname (sort(keys %sub)) {
			print OUT $subname,"\n";
		    }
		    next CMD; };
		$cmd =~ s/^X\b/V $pkg/;
		$cmd =~ /^V$/ && do {
		    $cmd = "V $pkg"; };
		$cmd =~ /^V\b\s*(\S+)\s*(.*)/ && do {
		    local ($savout) = select(OUT);
		    $packname = $1;
		    @vars = split(' ',$2);
		    do 'dumpvar.pl' unless defined &main::dumpvar;
		    if (defined &main::dumpvar) {
			&main::dumpvar($packname,@vars);
		    }
		    else {
			print DB::OUT "dumpvar.pl not available.\n";
		    }
		    select ($savout);
		    next CMD; };
		$cmd =~ /^f\b\s*(.*)/ && do {
		    $file = $1;
		    if (!$file) {
			print OUT "The old f command is now the r command.\n";
			print OUT "The new f command switches filenames.\n";
			next CMD;
		    }
		    if (!defined $main::{'_<' . $file}) {
			if (($try) = grep(m#^_<.*$file#, keys %main::)) {
			    $file = substr($try,2);
			    print "\n$file:\n";
			}
		    }
		    if (!defined $main::{'_<' . $file}) {
			print OUT "There's no code here anything matching $file.\n";
			next CMD;
		    }
		    elsif ($file ne $filename) {
			*dbline = "::_<$file";
			$max = $#dbline;
			$filename = $file;
			$start = 1;
			$cmd = "l";
		    } };
		$cmd =~ /^l\b\s*([':A-Za-z_][':\w]*)/ && do {
		    $subname = $1;
		    $subname = "main::" . $subname unless $subname =~ /'|::/;
		    $subname = "main" . $subname if substr($subname,0,1)eq "'";
		    $subname = "main" . $subname if substr($subname,0,2)eq "::";
		    # VMS filespecs may (usually do) contain ':', so don't use split
		    ($file,$subrange) = $sub{$subname} =~ /(.*):(.*)/;
		    if ($file ne $filename) {
			*dbline = "::_<$file";
			$max = $#dbline;
			$filename = $file;
		    }
		    if ($subrange) {
			if (eval($subrange) < -$window) {
			    $subrange =~ s/-.*/+/;
			}
			$cmd = "l $subrange";
		    } else {
			print OUT "Subroutine $1 not found.\n";
			next CMD;
		    } };
		$cmd =~ /^w\b\s*(\d*)$/ && do {
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
		$cmd =~ /^l\b\s*(\d*)\+(\d*)$/ && do {
		    $start = $1 if $1;
		    $incr = $2;
		    $incr = $window - 1 unless $incr;
		    $cmd = 'l ' . $start . '-' . ($start + $incr); };
		$cmd =~ /^l\b\s*(([\d\$\.]+)([-,]([\d\$\.]+))?)?/ && do {
		    $end = (!$2) ? $max : ($4 ? $4 : $2);
		    $end = $max if $end > $max;
		    $i = $2;
		    $i = $line if $i eq '.';
		    $i = 1 if $i < 1;
		    if ($emacs) {
			print OUT "\032\032$filename:$i:0\n";
			$i = $end;
		    } else {
			for (; $i <= $end; $i++) {
			    print OUT "$i:\t", $dbline[$i];
			    last if $signal;
			}
		    }
		    $start = $i;	# remember in case they want more
		    $start = $max if $start > $max;
		    next CMD; };
		$cmd =~ /^D$/ && do {
		    print OUT "Deleting all breakpoints...\n";
		    for ($i = 1; $i <= $max ; $i++) {
			if (defined $dbline{$i}) {
			    $dbline{$i} =~ s/^[^\0]+//;
			    if ($dbline{$i} =~ s/^\0?$//) {
				delete $dbline{$i};
			    }
			}
		    }
		    next CMD; };
		$cmd =~ /^L$/ && do {
		    for ($i = 1; $i <= $max; $i++) {
			if (defined $dbline{$i}) {
			    print OUT "$i:\t", $dbline[$i];
			    ($stop,$action) = split(/\0/, $dbline{$i});
			    print OUT "  break if (", $stop, ")\n" 
				if $stop;
			    print OUT "  action:  ", $action, "\n" 
				if $action;
			    last if $signal;
			}
		    }
		    next CMD; };
		$cmd =~ /^b\b\s*([':A-Za-z_][':\w]*)\s*(.*)/ && do {
		    $subname = $1;
		    $cond = $2 || '1';
		    $subname = "${pkg}::" . $subname
			unless $subname =~ /'|::/;
		    $subname = "main" . $subname if substr($subname,0,1) eq "'";
		    $subname = "main" . $subname if substr($subname,0,2) eq "::";
		    # VMS filespecs may (usually do) contain ':', so don't use split
		    ($filename,$i) = $sub{$subname} =~ /(.*):(.*)/;
		    $i += 0;
		    if ($i) {
			*dbline = "::_<$filename";
			++$i while $dbline[$i] == 0 && $i < $#dbline;
			$dbline{$i} =~ s/^[^\0]*/$cond/;
		    } else {
			print OUT "Subroutine $subname not found.\n";
		    }
		    next CMD; };
		$cmd =~ /^b\b\s*(\d*)\s*(.*)/ && do {
		    $i = ($1?$1:$line);
		    $cond = $2 || '1';
		    if ($dbline[$i] == 0) {
			print OUT "Line $i not breakable.\n";
		    } else {
			$dbline{$i} =~ s/^[^\0]*/$cond/;
		    }
		    next CMD; };
		$cmd =~ /^d\b\s*(\d+)?/ && do {
		    $i = ($1?$1:$line);
		    $dbline{$i} =~ s/^[^\0]*//;
		    delete $dbline{$i} if $dbline{$i} eq '';
		    next CMD; };
		$cmd =~ /^A$/ && do {
		    for ($i = 1; $i <= $max ; $i++) {
			if (defined $dbline{$i}) {
			    $dbline{$i} =~ s/\0[^\0]*//;
			    delete $dbline{$i} if $dbline{$i} eq '';
			}
		    }
		    next CMD; };
		$cmd =~ /^<\s*(.*)/ && do {
		    $pre = action($1);
		    next CMD; };
		$cmd =~ /^>\s*(.*)/ && do {
		    $post = action($1);
		    next CMD; };
		$cmd =~ /^a\b\s*(\d+)(\s+(.*))?/ && do {
		    $i = $1;
		    if ($dbline[$i] == 0) {
			print OUT "Line $i may not have an action.\n";
		    } else {
			$dbline{$i} =~ s/\0[^\0]*//;
			$dbline{$i} .= "\0" . action($3);
		    }
		    next CMD; };
		$cmd =~ /^n$/ && do {
		    $single = 2;
		    $laststep = $cmd;
		    last CMD; };
		$cmd =~ /^s$/ && do {
		    $single = 1;
		    $laststep = $cmd;
		    last CMD; };
		$cmd =~ /^c\b\s*(\d*)\s*$/ && do {
		    $i = $1;
		    if ($i) {
			if ($dbline[$i] == 0) {
			    print OUT "Line $i not breakable.\n";
			    next CMD;
			}
			$dbline{$i} =~ s/(\0|$)/;9$1/;	# add one-time-only b.p.
		    }
		    for ($i=0; $i <= $#stack; ) {
			$stack[$i++] &= ~1;
		    }
		    last CMD; };
		$cmd =~ /^r$/ && do {
		    $stack[$#stack] |= 2;
		    last CMD; };
		$cmd =~ /^T$/ && do {
		    local($p,$f,$l,$s,$h,$a,@a,@sub);
		    for ($i = 1; ($p,$f,$l,$s,$h,$w) = caller($i); $i++) {
			@a = ();
			for $arg (@args) {
			    $_ = "$arg";
			    s/'/\\'/g;
			    s/([^\0]*)/'$1'/
				unless /^(?: -?[\d.]+ | \*[\w:]* )$/x;
			    s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
			    s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
			    push(@a, $_);
			}
			$w = $w ? '@ = ' : '$ = ';
			$a = $h ? '(' . join(', ', @a) . ')' : '';
			push(@sub, "$w$s$a from file $f line $l\n");
			last if $signal;
		    }
		    for ($i=0; $i <= $#sub; $i++) {
			last if $signal;
			print OUT $sub[$i];
		    }
		    next CMD; };
		$cmd =~ /^\/(.*)$/ && do {
		    $inpat = $1;
		    $inpat =~ s:([^\\])/$:$1:;
		    if ($inpat ne "") {
			eval '$inpat =~ m'."\a$inpat\a";	
			if ($@ ne "") {
			    print OUT "$@";
			    next CMD;
			}
			$pat = $inpat;
		    }
		    $end = $start;
		    eval '
		    for (;;) {
			++$start;
			$start = 1 if ($start > $max);
			last if ($start == $end);
			if ($dbline[$start] =~ m'."\a$pat\a".'i) {
			    if ($emacs) {
				print OUT "\032\032$filename:$start:0\n";
			    } else {
				print OUT "$start:\t", $dbline[$start], "\n";
			    }
			    last;
			}
		    } ';
		    print OUT "/$pat/: not found\n" if ($start == $end);
		    next CMD; };
		$cmd =~ /^\?(.*)$/ && do {
		    $inpat = $1;
		    $inpat =~ s:([^\\])\?$:$1:;
		    if ($inpat ne "") {
			eval '$inpat =~ m'."\a$inpat\a";	
			if ($@ ne "") {
			    print OUT "$@";
			    next CMD;
			}
			$pat = $inpat;
		    }
		    $end = $start;
		    eval '
		    for (;;) {
			--$start;
			$start = $max if ($start <= 0);
			last if ($start == $end);
			if ($dbline[$start] =~ m'."\a$pat\a".'i) {
			    if ($emacs) {
				print OUT "\032\032$filename:$start:0\n";
			    } else {
				print OUT "$start:\t", $dbline[$start], "\n";
			    }
			    last;
			}
		    } ';
		    print OUT "?$pat?: not found\n" if ($start == $end);
		    next CMD; };
		$cmd =~ /^!+\s*(-)?(\d+)?$/ && do {
		    pop(@hist) if length($cmd) > 1;
		    $i = ($1?($#hist-($2?$2:1)):($2?$2:$#hist));
		    $cmd = $hist[$i] . "\n";
		    print OUT $cmd;
		    redo CMD; };
		$cmd =~ /^!(.+)$/ && do {
		    $pat = "^$1";
		    pop(@hist) if length($cmd) > 1;
		    for ($i = $#hist; $i; --$i) {
			last if $hist[$i] =~ $pat;
		    }
		    if (!$i) {
			print OUT "No such command!\n\n";
			next CMD;
		    }
		    $cmd = $hist[$i] . "\n";
		    print OUT $cmd;
		    redo CMD; };
		$cmd =~ /^H\b\s*(-(\d+))?/ && do {
		    $end = $2?($#hist-$2):0;
		    $hist = 0 if $hist < 0;
		    for ($i=$#hist; $i>$end; $i--) {
			print OUT "$i: ",$hist[$i],"\n"
			    unless $hist[$i] =~ /^.?$/;
		    };
		    next CMD; };
		$cmd =~ s/^p( .*)?$/print DB::OUT$1/;
		$cmd =~ /^=/ && do {
		    if (local($k,$v) = ($cmd =~ /^=\s*(\S+)\s+(.*)/)) {
			$alias{$k}="s~$k~$v~";
			print OUT "$k = $v\n";
		    } elsif ($cmd =~ /^=\s*$/) {
			foreach $k (sort keys(%alias)) {
			    if (($v = $alias{$k}) =~ s~^s\~$k\~(.*)\~$~$1~) {
				print OUT "$k = $v\n";
			    } else {
				print OUT "$k\t$alias{$k}\n";
			    };
			};
		    };
		    next CMD; };
	    }
	    $evalarg = $cmd; &eval;
	    print OUT "\n";
	}
	if ($post) {
	    $evalarg = $post; &eval;
	}
    }
    ($@, $!, $,, $/, $\, $^W) = @saved;
    ();
}

sub save {
    @saved = ($@, $!, $,, $/, $\, $^W);
    $, = ""; $/ = "\n"; $\ = ""; $^W = 0;
}

# The following takes its argument via $evalarg to preserve current @_

sub eval {
    eval "$usercontext $evalarg; &DB::save";
    print OUT $@;
}

sub action {
    local($action) = @_;
    while ($action =~ s/\\$//) {
	print OUT "+ ";
	$action .= &gets;
    }
    $action;
}

sub gets {
    local($.);
    <IN>;
}

sub catch {
    $signal = 1;
}

sub sub {
    push(@stack, $single);
    $single &= 1;
    $single |= 4 if $#stack == $deep;
    if (wantarray) {
	@i = &$sub;
	$single |= pop(@stack);
	@i;
    }
    else {
	$i = &$sub;
	$single |= pop(@stack);
	$i;
    }
}

$trace = $signal = $single = 0;	# uninitialized warning suppression

@hist = ('?');
$SIG{'INT'} = "DB::catch";
$deep = 100;		# warning if stack gets this deep
$window = 10;
$preview = 3;

@stack = (0);
@ARGS = @ARGV;
for (@args) {
    s/'/\\'/g;
    s/(.*)/'$1'/ unless /^-?[\d.]+$/;
}

if (-f $rcfile) {
    do "./$rcfile";
}
elsif (-f "$ENV{'LOGDIR'}/$rcfile") {
    do "$ENV{'LOGDIR'}/$rcfile";
}
elsif (-f "$ENV{'HOME'}/$rcfile") {
    do "$ENV{'HOME'}/$rcfile";
}

1;
