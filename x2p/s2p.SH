: This forces SH files to create target in same directory as SH file.
: This is so that make depend always knows where to find SH derivatives.
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
case $CONFIG in
'')
    if test ! -f config.sh; then
	ln ../config.sh . || \
	ln ../../config.sh . || \
	ln ../../../config.sh . || \
	(echo "Can't find config.sh."; exit 1)
    fi
    . config.sh
    ;;
esac
echo "Extracting s2p (with variable substitutions)"
: This section of the file will have variable substitutions done on it.
: Move anything that needs config subs from !NO!SUBS! section to !GROK!THIS!.
: Protect any dollar signs and backticks that you do not want interpreted
: by putting a backslash in front.  You may delete these comments.
$spitshell >s2p <<!GROK!THIS!
#!$bin/perl

\$bin = '$bin';
!GROK!THIS!

: In the following dollars and backticks do not need the extra backslash.
$spitshell >>s2p <<'!NO!SUBS!'

# $Header: s2p.SH,v 3.0 89/10/18 15:35:02 lwall Locked $
#
# $Log:	s2p.SH,v $
# Revision 3.0  89/10/18  15:35:02  lwall
# 3.0 baseline
# 
# Revision 2.0.1.1  88/07/11  23:26:23  root
# patch2: s2p didn't put a proper prologue on output script
# 
# Revision 2.0  88/06/05  00:15:55  root
# Baseline version 2.0.
# 
#

$indent = 4;
$shiftwidth = 4;
$l = '{'; $r = '}';
$tempvar = '1';

while ($ARGV[0] =~ '^-') {
    $_ = shift;
  last if /^--/;
    if (/^-D/) {
	$debug++;
	open(body,'>-');
	next;
    }
    if (/^-n/) {
	$assumen++;
	next;
    }
    if (/^-p/) {
	$assumep++;
	next;
    }
    die "I don't recognize this switch: $_\n";
}

unless ($debug) {
    open(body,">/tmp/sperl$$") || do Die("Can't open temp file");
}

if (!$assumen && !$assumep) {
    print body
'while ($ARGV[0] =~ /^-/) {
    $_ = shift;
  last if /^--/;
    if (/^-n/) {
	$nflag++;
	next;
    }
    die "I don\'t recognize this switch: $_\\n";
}

';
}

print body '
#ifdef PRINTIT
#ifdef ASSUMEP
$printit++;
#else
$printit++ unless $nflag;
#endif
#endif
line: while (<>) {
';

line: while (<>) {
    s/[ \t]*(.*)\n$/$1/;
    if (/^:/) {
	s/^:[ \t]*//;
	$label = do make_label($_);
	if ($. == 1) {
	    $toplabel = $label;
	}
	$_ = "$label:";
	if ($lastlinewaslabel++) {$_ .= "\t;";}
	if ($indent >= 2) {
	    $indent -= 2;
	    $indmod = 2;
	}
	next;
    } else {
	$lastlinewaslabel = '';
    }
    $addr1 = '';
    $addr2 = '';
    if (s/^([0-9]+)//) {
	$addr1 = "$1";
    }
    elsif (s/^\$//) {
	$addr1 = 'eof()';
    }
    elsif (s|^/||) {
	$addr1 = do fetchpat('/');
    }
    if (s/^,//) {
	if (s/^([0-9]+)//) {
	    $addr2 = "$1";
	} elsif (s/^\$//) {
	    $addr2 = "eof()";
	} elsif (s|^/||) {
	    $addr2 = do fetchpat('/');
	} else {
	    do Die("Invalid second address at line $.\n");
	}
	$addr1 .= " .. $addr2";
    }
					# a { to keep vi happy
    s/^[ \t]+//;
    if ($_ eq '}') {
	$indent -= 4;
	next;
    }
    if (s/^!//) {
	$if = 'unless';
	$else = "$r else $l\n";
    } else {
	$if = 'if';
	$else = '';
    }
    if (s/^{//) {	# a } to keep vi happy
	$indmod = 4;
	$redo = $_;
	$_ = '';
	$rmaybe = '';
    } else {
	$rmaybe = "\n$r";
	if ($addr2 || $addr1) {
	    $space = ' ' x $shiftwidth;
	} else {
	    $space = '';
	}
	$_ = do transmogrify();
    }

    if ($addr1) {
	if ($_ !~ /[\n{}]/ && $rmaybe && !$change &&
	  $_ !~ / if / && $_ !~ / unless /) {
	    s/;$/ $if $addr1;/;
	    $_ = substr($_,$shiftwidth,1000);
	} else {
	    $command = $_;
	    $_ = "$if ($addr1) $l\n$change$command$rmaybe";
	}
	$change = '';
	next line;
    }
} continue {
    @lines = split(/\n/,$_);
    while ($#lines >= 0) {
	$_ = shift(lines);
	unless (s/^ *<<--//) {
	    print body "\t" x ($indent / 8), ' ' x ($indent % 8);
	}
	print body $_, "\n";
    }
    $indent += $indmod;
    $indmod = 0;
    if ($redo) {
	$_ = $redo;
	$redo = '';
	redo line;
    }
}

print body "}\n";
if ($appendseen || $tseen || !$assumen) {
    $printit++ if $dseen || (!$assumen && !$assumep);
    print body '
continue {
#ifdef PRINTIT
#ifdef DSEEN
#ifdef ASSUMEP
    print if $printit++;
#else
    if ($printit) { print;} else { $printit++ unless $nflag; }
#endif
#else
    print if $printit;
#endif
#else
    print;
#endif
#ifdef TSEEN
    $tflag = \'\';
#endif
#ifdef APPENDSEEN
    if ($atext) { print $atext; $atext = \'\'; }
#endif
}
';
}

close body;

unless ($debug) {
    open(head,">/tmp/sperl2$$.c") || do Die("Can't open temp file 2");
    print head "#define PRINTIT\n" if ($printit);
    print head "#define APPENDSEEN\n" if ($appendseen);
    print head "#define TSEEN\n" if ($tseen);
    print head "#define DSEEN\n" if ($dseen);
    print head "#define ASSUMEN\n" if ($assumen);
    print head "#define ASSUMEP\n" if ($assumep);
    if ($opens) {print head "$opens\n";}
    open(body,"/tmp/sperl$$") || do Die("Can't reopen temp file");
    while (<body>) {
	print head $_;
    }
    close head;

    print "#!$bin/perl
eval \"exec $bin/perl -S \$0 \$*\"
	if \$running_under_some_shell;

";
    open(body,"cc -E /tmp/sperl2$$.c |") ||
	do Die("Can't reopen temp file");
    while (<body>) {
	/^# [0-9]/ && next;
	/^[ \t]*$/ && next;
	s/^<><>//;
	print;
    }
}

unlink "/tmp/sperl$$", "/tmp/sperl2$$";

sub Die {
    unlink "/tmp/sperl$$", "/tmp/sperl2$$";
    die $_[0];
}
sub make_filehandle {
    $fname = $_ = $_[0];
    s/[^a-zA-Z]/_/g;
    s/^_*//;
    if (/^([a-z])([a-z]*)$/) {
	$first = $1;
	$rest = $2;
	$first =~ y/a-z/A-Z/;
	$_ = $first . $rest;
    }
    if (!$seen{$_}) {
	$opens .= "open($_,'>$fname') || die \"Can't create $fname\";\n";
    }
    $seen{$_} = $_;
}

sub make_label {
    $label = $_[0];
    $label =~ s/[^a-zA-Z0-9]/_/g;
    if ($label =~ /^[0-9_]/) { $label = 'L' . $label; }
    $label = substr($label,0,8);
    if ($label =~ /^([a-z])([a-z]*)$/) {	# could be reserved word
	$first = $1;
	$rest = $2;
	$first =~ y/a-z/A-Z/;			# so capitalize it
	$label = $first . $rest;
    }
    $label;
}

sub transmogrify {
    {	# case
	if (/^d/) {
	    $dseen++;
	    $_ = '
<<--#ifdef PRINTIT
$printit = \'\';
<<--#endif
next line;';
	    next;
	}

	if (/^n/) {
	    $_ =
'<<--#ifdef PRINTIT
<<--#ifdef DSEEN
<<--#ifdef ASSUMEP
print if $printit++;
<<--#else
if ($printit) { print;} else { $printit++ unless $nflag; }
<<--#endif
<<--#else
print if $printit;
<<--#endif
<<--#else
print;
<<--#endif
<<--#ifdef APPENDSEEN
if ($atext) {print $atext; $atext = \'\';}
<<--#endif
$_ = <>;
<<--#ifdef TSEEN
$tflag = \'\';
<<--#endif';
	    next;
	}

	if (/^a/) {
	    $appendseen++;
	    $command = $space .  '$atext .=' . "\n<<--'";
	    $lastline = 0;
	    while (<>) {
		s/^[ \t]*//;
		s/^[\\]//;
		unless (s|\\$||) { $lastline = 1;}
		s/'/\\'/g;
		s/^([ \t]*\n)/<><>$1/;
		$command .= $_;
		$command .= '<<--';
		last if $lastline;
	    }
	    $_ = $command . "';";
	    last;
	}

	if (/^[ic]/) {
	    if (/^c/) { $change = 1; }
	    $addr1 = '$iter = (' . $addr1 . ')';
	    $command = $space .  'if ($iter == 1) { print' . "\n<<--'";
	    $lastline = 0;
	    while (<>) {
		s/^[ \t]*//;
		s/^[\\]//;
		unless (s/\\$//) { $lastline = 1;}
		s/'/\\'/g;
		s/^([ \t]*\n)/<><>$1/;
		$command .= $_;
		$command .= '<<--';
		last if $lastline;
	    }
	    $_ = $command . "';}";
	    if ($change) {
		$dseen++;
		$change = "$_\n";
		$_ = "
<<--#ifdef PRINTIT
$space\$printit = '';
<<--#endif
${space}next line;";
	    }
	    last;
	}

	if (/^s/) {
	    $delim = substr($_,1,1);
	    $len = length($_);
	    $repl = $end = 0;
	    $inbracket = 0;
	    for ($i = 2; $i < $len; $i++) {
		$c = substr($_,$i,1);
		if ($c eq $delim) {
		    if ($inbracket) {
			$_ = substr($_,0,$i) . '\\' . substr($_,$i,10000);
			$i++;
			$len++;
		    }
		    else {
			if ($repl) {
			    $end = $i;
			    last;
			} else {
			    $repl = $i;
			}
		    }
		}
		elsif ($c eq '\\') {
		    $i++;
		    if ($i >= $len) {
			$_ .= 'n';
			$_ .= <>;
			$len = length($_);
			$_ = substr($_,0,--$len);
		    }
		    elsif (!$repl && substr($_,$i,1) =~ /^[(){}\w]$/) {
			$i--;
			$len--;
			$_ = substr($_,0,$i) . substr($_,$i+1,10000);
		    }
		}
		elsif ($c eq '[' && !$repl) {
		    $i++ if substr($_,$i,1) eq '^';
		    $i++ if substr($_,$i,1) eq ']';
		    $inbracket = 1;
		}
		elsif ($c eq ']') {
		    $inbracket = 0;
		}
		elsif (!$repl && index("()",$c) >= 0) {
		    $_ = substr($_,0,$i) . '\\' . substr($_,$i,10000);
		    $i++;
		    $len++;
		}
	    }
	    do Die("Malformed substitution at line $.\n") unless $end;
	    $pat = substr($_, 0, $repl + 1);
	    $repl = substr($_, $repl + 1, $end - $repl - 1);
	    $end = substr($_, $end + 1, 1000);
	    $dol = '$';
	    $repl =~ s/\$/\\$/;
	    $repl =~ s'&'$&'g;
	    $repl =~ s/[\\]([0-9])/$dol$1/g;
	    $subst = "$pat$repl$delim";
	    $cmd = '';
	    while ($end) {
		if ($end =~ s/^g//) { $subst .= 'g'; next; }
		if ($end =~ s/^p//) { $cmd .= ' && (print)'; next; }
		if ($end =~ s/^w[ \t]*//) {
		    $fh = do make_filehandle($end);
		    $cmd .= " && (print $fh \$_)";
		    $end = '';
		    next;
		}
		do Die("Unrecognized substitution command ($end) at line $.\n");
	    }
	    $_ =
"<<--#ifdef TSEEN
$subst && \$tflag++$cmd;
<<--#else
$subst$cmd;
<<--#endif";
	    next;
	}

	if (/^p/) {
	    $_ = 'print;';
	    next;
	}

	if (/^w/) {
	    s/^w[ \t]*//;
	    $fh = do make_filehandle($_);
	    $_ = "print $fh \$_;";
	    next;
	}

	if (/^r/) {
	    $appendseen++;
	    s/^r[ \t]*//;
	    $file = $_;
	    $_ = "\$atext .= `cat $file 2>/dev/null`;";
	    next;
	}

	if (/^P/) {
	    $_ = 'print $1 if /(^.*\n)/;';
	    next;
	}

	if (/^D/) {
	    $_ =
's/^.*\n//;
redo line if $_;
next line;';
	    next;
	}

	if (/^N/) {
	    $_ = '
$_ .= <>;
<<--#ifdef TSEEN
$tflag = \'\';
<<--#endif';
	    next;
	}

	if (/^h/) {
	    $_ = '$hold = $_;';
	    next;
	}

	if (/^H/) {
	    $_ = '$hold .= $_ ? $_ : "\n";';
	    next;
	}

	if (/^g/) {
	    $_ = '$_ = $hold;';
	    next;
	}

	if (/^G/) {
	    $_ = '$_ .= $hold ? $hold : "\n";';
	    next;
	}

	if (/^x/) {
	    $_ = '($_, $hold) = ($hold, $_);';
	    next;
	}

	if (/^b$/) {
	    $_ = 'next line;';
	    next;
	}

	if (/^b/) {
	    s/^b[ \t]*//;
	    $lab = do make_label($_);
	    if ($lab eq $toplabel) {
		$_ = 'redo line;';
	    } else {
		$_ = "goto $lab;";
	    }
	    next;
	}

	if (/^t$/) {
	    $_ = 'next line if $tflag;';
	    $tseen++;
	    next;
	}

	if (/^t/) {
	    s/^t[ \t]*//;
	    $lab = do make_label($_);
	    if ($lab eq $toplabel) {
		$_ = 'if ($tflag) {$tflag = \'\'; redo line;}';
	    } else {
		$_ = "if (\$tflag) {\$tflag = ''; goto $lab;}";
	    }
	    $tseen++;
	    next;
	}

	if (/^=/) {
	    $_ = 'print "$.\n";';
	    next;
	}

	if (/^q/) {
	    $_ =
'close(ARGV);
@ARGV = ();
next line;';
	    next;
	}
    } continue {
	if ($space) {
	    s/^/$space/;
	    s/(\n)(.)/$1$space$2/g;
	}
	last;
    }
    $_;
}

sub fetchpat {
    local($outer) = @_;
    local($addr) = $outer;
    local($inbracket);
    local($prefix,$delim,$ch);

    delim: while (s:^([^\](|)[\\/]*)([](|)[\\/])::) {
	$prefix = $1;
	$delim = $2;
	print "$prefix\t$delim\t$_\n";
	if ($delim eq '\\') {
	    s/(.)//;
	    $ch = $1;
	    $delim = '' if $ch =~ /^[(){}\w]$/;
	    $delim .= $1;
	}
	elsif ($delim eq '[') {
	    $inbracket = 1;
	    s/^\^// && ($delim .= '^');
	    s/^]// && ($delim .= ']');
	    print "$prefix\t$delim\t$_\n";
	}
	elsif ($delim eq ']') {
	    $inbracket = 0;
	}
	elsif ($inbracket || $delim ne $outer) {
	    print "Adding\n";
	    $delim = '\\' . $delim;
	}
	$addr .= $prefix;
	$addr .= $delim;
	if ($delim eq $outer && !$inbracket) {
	    last delim;
	}
    }
    $addr;
}

!NO!SUBS!
chmod 755 s2p
$eunicefix s2p
