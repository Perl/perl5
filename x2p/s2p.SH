: This forces SH files to create target in same directory as SH file.
: This is so that make depend always knows where to find SH derivatives.
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
case $CONFIG in
'')
    if test ! -f config.sh; then
	ln ../config.sh . || \
	ln -s ../config.sh . || \
	ln ../../config.sh . || \
	ln ../../../config.sh . || \
	(echo "Can't find config.sh."; exit 1)
    fi 2>/dev/null
    . ./config.sh
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

# $Header: s2p.SH,v 4.0 91/03/20 01:57:59 lwall Locked $
#
# $Log:	s2p.SH,v $
# Revision 4.0  91/03/20  01:57:59  lwall
# 4.0 baseline.
# 
#

$indent = 4;
$shiftwidth = 4;
$l = '{'; $r = '}';

while ($ARGV[0] =~ /^-/) {
    $_ = shift;
  last if /^--/;
    if (/^-D/) {
	$debug++;
	open(BODY,'>-');
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
    open(BODY,">/tmp/sperl$$") ||
      &Die("Can't open temp file: $!\n");
}

if (!$assumen && !$assumep) {
    print BODY <<'EOT';
while ($ARGV[0] =~ /^-/) {
    $_ = shift;
  last if /^--/;
    if (/^-n/) {
	$nflag++;
	next;
    }
    die "I don't recognize this switch: $_\\n";
}

EOT
}

print BODY <<'EOT';

#ifdef PRINTIT
#ifdef ASSUMEP
$printit++;
#else
$printit++ unless $nflag;
#endif
#endif
LINE: while (<>) {
EOT

LINE: while (<>) {

    # Wipe out surrounding whitespace.

    s/[ \t]*(.*)\n$/$1/;

    # Perhaps it's a label/comment.

    if (/^:/) {
	s/^:[ \t]*//;
	$label = &make_label($_);
	if ($. == 1) {
	    $toplabel = $label;
	}
	$_ = "$label:";
	if ($lastlinewaslabel++) {
	    $indent += 4;
	    print BODY &tab, ";\n";
	    $indent -= 4;
	}
	if ($indent >= 2) {
	    $indent -= 2;
	    $indmod = 2;
	}
	next;
    } else {
	$lastlinewaslabel = '';
    }

    # Look for one or two address clauses

    $addr1 = '';
    $addr2 = '';
    if (s/^([0-9]+)//) {
	$addr1 = "$1";
    }
    elsif (s/^\$//) {
	$addr1 = 'eof()';
    }
    elsif (s|^/||) {
	$addr1 = &fetchpat('/');
    }
    if (s/^,//) {
	if (s/^([0-9]+)//) {
	    $addr2 = "$1";
	} elsif (s/^\$//) {
	    $addr2 = "eof()";
	} elsif (s|^/||) {
	    $addr2 = &fetchpat('/');
	} else {
	    &Die("Invalid second address at line $.\n");
	}
	$addr1 .= " .. $addr2";
    }

    # Now we check for metacommands {, }, and ! and worry
    # about indentation.

    s/^[ \t]+//;
    # a { to keep vi happy
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
	$_ = &transmogrify();
    }

    # See if we can optimize to modifier form.

    if ($addr1) {
	if ($_ !~ /[\n{}]/ && $rmaybe && !$change &&
	  $_ !~ / if / && $_ !~ / unless /) {
	    s/;$/ $if $addr1;/;
	    $_ = substr($_,$shiftwidth,1000);
	} else {
	    $_ = "$if ($addr1) $l\n$change$_$rmaybe";
	}
	$change = '';
	next LINE;
    }
} continue {
    @lines = split(/\n/,$_);
    for (@lines) {
	unless (s/^ *<<--//) {
	    print BODY &tab;
	}
	print BODY $_, "\n";
    }
    $indent += $indmod;
    $indmod = 0;
    if ($redo) {
	$_ = $redo;
	$redo = '';
	redo LINE;
    }
}
if ($lastlinewaslabel++) {
    $indent += 4;
    print BODY &tab, ";\n";
    $indent -= 4;
}

print BODY "}\n";
if ($appendseen || $tseen || !$assumen) {
    $printit++ if $dseen || (!$assumen && !$assumep);
    print BODY <<'EOT';

continue {
#ifdef PRINTIT
#ifdef DSEEN
#ifdef ASSUMEP
    print if $printit++;
#else
    if ($printit)
	{ print; }
    else
	{ $printit++ unless $nflag; }
#endif
#else
    print if $printit;
#endif
#else
    print;
#endif
#ifdef TSEEN
    $tflag = '';
#endif
#ifdef APPENDSEEN
    if ($atext) { print $atext; $atext = ''; }
#endif
}
EOT
}

close BODY;

unless ($debug) {
    open(HEAD,">/tmp/sperl2$$.c")
      || &Die("Can't open temp file 2: $!\n");
    print HEAD "#define PRINTIT\n" if ($printit);
    print HEAD "#define APPENDSEEN\n" if ($appendseen);
    print HEAD "#define TSEEN\n" if ($tseen);
    print HEAD "#define DSEEN\n" if ($dseen);
    print HEAD "#define ASSUMEN\n" if ($assumen);
    print HEAD "#define ASSUMEP\n" if ($assumep);
    if ($opens) {print HEAD "$opens\n";}
    open(BODY,"/tmp/sperl$$")
      || &Die("Can't reopen temp file: $!\n");
    while (<BODY>) {
	print HEAD $_;
    }
    close HEAD;

    print <<"EOT";
#!$bin/perl
eval 'exec $bin/perl -S \$0 \$*'
	if \$running_under_some_shell;

EOT
    open(BODY,"cc -E /tmp/sperl2$$.c |") ||
	&Die("Can't reopen temp file: $!\n");
    while (<BODY>) {
	/^# [0-9]/ && next;
	/^[ \t]*$/ && next;
	s/^<><>//;
	print;
    }
}

&Cleanup;
exit;

sub Cleanup {
    chdir "/tmp";
    unlink "sperl$$", "sperl2$$", "sperl2$$.c";
}
sub Die {
    &Cleanup;
    die $_[0];
}
sub tab {
    "\t" x ($indent / 8) . ' ' x ($indent % 8);
}
sub make_filehandle {
    local($_) = $_[0];
    local($fname) = $_;
    s/[^a-zA-Z]/_/g;
    s/^_*//;
    substr($_,0,1) =~ y/a-z/A-Z/ if /^[a-z]/;
    if (!$seen{$_}) {
	$opens .= <<"EOT";
open($_,'>$fname') || die "Can't create $fname";
EOT
    }
    $seen{$_} = $_;
}

sub make_label {
    local($label) = @_;
    $label =~ s/[^a-zA-Z0-9]/_/g;
    if ($label =~ /^[0-9_]/) { $label = 'L' . $label; }
    $label = substr($label,0,8);

    # Could be a reserved word, so capitalize it.
    substr($label,0,1) =~ y/a-z/A-Z/
      if $label =~ /^[a-z]/;

    $label;
}

sub transmogrify {
    {	# case
	if (/^d/) {
	    $dseen++;
	    chop($_ = <<'EOT');
<<--#ifdef PRINTIT
$printit = '';
<<--#endif
next LINE;
EOT
	    next;
	}

	if (/^n/) {
	    chop($_ = <<'EOT');
<<--#ifdef PRINTIT
<<--#ifdef DSEEN
<<--#ifdef ASSUMEP
print if $printit++;
<<--#else
if ($printit)
    { print; }
else
    { $printit++ unless $nflag; }
<<--#endif
<<--#else
print if $printit;
<<--#endif
<<--#else
print;
<<--#endif
<<--#ifdef APPENDSEEN
if ($atext) {print $atext; $atext = '';}
<<--#endif
$_ = <>;
<<--#ifdef TSEEN
$tflag = '';
<<--#endif
EOT
	    next;
	}

	if (/^a/) {
	    $appendseen++;
	    $command = $space . '$atext .=' . "\n<<--'";
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
	    $command = $space . 'if ($iter == 1) { print'
	      . "\n<<--'";
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
		chop($_ = <<"EOT");
<<--#ifdef PRINTIT
$space\$printit = '';
<<--#endif
${space}next LINE;
EOT
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
			substr($_, $i, 0) = '\\';
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
		    elsif (substr($_,$i,1) =~ /^[n]$/) {
			;
		    }
		    elsif (!$repl &&
		      substr($_,$i,1) =~ /^[(){}\w]$/) {
			$i--;
			$len--;
			substr($_, $i, 1) = '';
		    }
		    elsif (!$repl &&
		      substr($_,$i,1) =~ /^[<>]$/) {
			substr($_,$i,1) = 'b';
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
		elsif (!$repl && index("()+",$c) >= 0) {
		    substr($_, $i, 0) = '\\';
		    $i++;
		    $len++;
		}
	    }
	    &Die("Malformed substitution at line $.\n")
	      unless $end;
	    $pat = substr($_, 0, $repl + 1);
	    $repl = substr($_, $repl+1, $end-$repl-1);
	    $end = substr($_, $end + 1, 1000);
	    $dol = '$';
	    $repl =~ s/\$/\\$/;
	    $repl =~ s'&'$&'g;
	    $repl =~ s/[\\]([0-9])/$dol$1/g;
	    $subst = "$pat$repl$delim";
	    $cmd = '';
	    while ($end) {
		if ($end =~ s/^g//) {
		    $subst .= 'g';
		    next;
		}
		if ($end =~ s/^p//) {
		    $cmd .= ' && (print)';
		    next;
		}
		if ($end =~ s/^w[ \t]*//) {
		    $fh = &make_filehandle($end);
		    $cmd .= " && (print $fh \$_)";
		    $end = '';
		    next;
		}
		&Die("Unrecognized substitution command".
		  "($end) at line $.\n");
	    }
	    chop ($_ = <<"EOT");
<<--#ifdef TSEEN
$subst && \$tflag++$cmd;
<<--#else
$subst$cmd;
<<--#endif
EOT
	    next;
	}

	if (/^p/) {
	    $_ = 'print;';
	    next;
	}

	if (/^w/) {
	    s/^w[ \t]*//;
	    $fh = &make_filehandle($_);
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
	    chop($_ = <<'EOT');
s/^.*\n//;
redo LINE if $_;
next LINE;
EOT
	    next;
	}

	if (/^N/) {
	    chop($_ = <<'EOT');
$_ .= <>;
<<--#ifdef TSEEN
$tflag = '';
<<--#endif
EOT
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
	    $_ = 'next LINE;';
	    next;
	}

	if (/^b/) {
	    s/^b[ \t]*//;
	    $lab = &make_label($_);
	    if ($lab eq $toplabel) {
		$_ = 'redo LINE;';
	    } else {
		$_ = "goto $lab;";
	    }
	    next;
	}

	if (/^t$/) {
	    $_ = 'next LINE if $tflag;';
	    $tseen++;
	    next;
	}

	if (/^t/) {
	    s/^t[ \t]*//;
	    $lab = &make_label($_);
	    $_ = q/if ($tflag) {$tflag = ''; /;
	    if ($lab eq $toplabel) {
		$_ .= 'redo LINE;}';
	    } else {
		$_ .= "goto $lab;}";
	    }
	    $tseen++;
	    next;
	}

	if (/^=/) {
	    $_ = 'print "$.\n";';
	    next;
	}

	if (/^q/) {
	    chop($_ = <<'EOT');
close(ARGV);
@ARGV = ();
next LINE;
EOT
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

    # Process pattern one potential delimiter at a time.

    DELIM: while (s#^([^\]+(|)[\\/]*)([]+(|)[\\/])##) {
	$prefix = $1;
	$delim = $2;
	if ($delim eq '\\') {
	    s/(.)//;
	    $ch = $1;
	    $delim = '' if $ch =~ /^[(){}A-Za-mo-z]$/;
	    $ch = 'b' if $ch =~ /^[<>]$/;
	    $delim .= $ch;
	}
	elsif ($delim eq '[') {
	    $inbracket = 1;
	    s/^\^// && ($delim .= '^');
	    s/^]// && ($delim .= ']');
	}
	elsif ($delim eq ']') {
	    $inbracket = 0;
	}
	elsif ($inbracket || $delim ne $outer) {
	    $delim = '\\' . $delim;
	}
	$addr .= $prefix;
	$addr .= $delim;
	if ($delim eq $outer && !$inbracket) {
	    last DELIM;
	}
    }
    $addr;
}

!NO!SUBS!
chmod 755 s2p
$eunicefix s2p
