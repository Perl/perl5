# Term::Cap.pm -- Termcap interface routines
package Term::Cap;

# Converted to package on 25 Feb 1994 <sanders@bsdi.com>
#
# Usage:
#	require 'ioctl.pl';
#	ioctl(TTY,$TIOCGETP,$sgtty);
#	($ispeed,$ospeed) = unpack('cc',$sgtty);
#
#	require Term::Cap;
#
#	$term = Tgetent Term::Cap { TERM => undef, OSPEED => $ospeed };
#		sets $term->{'_cm'}, etc.
#	$this->Trequire(qw/ce ku kd/);
#		die unless entries are defined for the terminal
#	$term->Tgoto('cm', $col, $row, $FH);
#	$term->Tputs('dl', $cnt = 1, $FH);
#	$this->Tpad($string, $cnt = 1, $FH);
#		processes a termcap string and adds padding if needed
#		if $FH is undefined these just return the string
#
# CHANGES:
#	Converted to package
#	Allows :tc=...: in $ENV{'TERMCAP'} (flows to default termcap file)
#	Now die's properly if it can't open $TERMCAP or if the eval $loop fails
#	Tputs() results are cached (use Tgoto or Tpad to avoid)
#	Tgoto() will do output if $FH is passed (like Tputs without caching)
#	Supports POSIX termios speeds and old style speeds
#	Searches termcaps properly (TERMPATH, etc)
#	The output routines are optimized for cached Tputs().
#	$this->{_xx} is the raw termcap data and $this->{xx} is a
#	    cached and padded string for count == 1.
#

# internal routines
sub getenv { defined $ENV{$_[0]} ? $ENV{$_[0]} : ''; }
sub termcap_path {
    local @termcap_path = ('/etc/termcap', '/usr/share/misc/termcap');
    local $v;
    if ($v = getenv(TERMPATH)) {
	# user specified path
	@termcap_path = split(':', $v);
    } else {
	# default path
	@termcap_path = ('/etc/termcap', '/usr/share/misc/termcap');
	$v = getenv(HOME);
	unshift(@termcap_path, $v . '/.termcap') if $v;
    }
    # we always search TERMCAP first
    $v = getenv(TERMCAP);
    unshift(@termcap_path, $v) if $v =~ /^\//;
    grep(-f, @termcap_path);
}

sub Tgetent {
    local($type) = shift;
    local($this) = @_;
    local($TERM,$TERMCAP,$term,$entry,$cap,$loop,$field,$entry,$_);

    warn "Tgetent: no ospeed set\n" unless $this->{OSPEED} > 0;
    $this->{DECR} = 10000 / $this->{OSPEED} if $this->{OSPEED} > 50;
    $term = $TERM = $this->{TERM} =
	$this->{TERM} || getenv(TERM) || die "Tgetent: TERM not set\n";

    $TERMCAP = getenv(TERMCAP);
    $TERMCAP = '' if $TERMCAP =~ m:^/: || $TERMCAP !~ /(^|\|)$TERM[:\|]/;
    local @termcap_path = &termcap_path;
    die "Tgetent: Can't find a valid termcap file\n"
	unless @termcap_path || $TERMCAP;

    # handle environment TERMCAP, setup for continuation if needed
    $entry = $TERMCAP;
    $entry =~ s/:tc=([^:]+):/:/ && ($TERM = $1);
    if ($TERMCAP eq '' || $1) {				# the search goes on
	local $first = $TERMCAP eq '' ? 1 : 0;		# make it pretty
	local $max = 32;				# max :tc=...:'s
	local $state = 1;				# 0 == finished
							# 1 == next file
							# 2 == search again
	do {
	    if ($state == 1) {
		$TERMCAP = shift @termcap_path
		    || die "Tgetent: failed lookup on $TERM\n";
	    } else {
		$max-- || die "Tgetent: termcap loop at $TERM\n";
		$state = 1;				# back to default state
	    }

	    open(TERMCAP,"< $TERMCAP\0") || die "Tgetent: $TERMCAP: $!\n";
	    # print STDERR "Trying... $TERMCAP\n";
	    $loop = "
		while (<TERMCAP>) {
		    next if /^\t/;
		    next if /^#/;
		    if (/(^|\\|)${TERM}[:\\|]/) {
			chop;
			s/^[^:]*:// unless \$first++;
			\$state = 0;
			while (chop eq '\\\\') {
			    \$_ .= <TERMCAP>;
			    chop;
			}
			\$_ .= ':';
			last;
		    }
		}
		\$entry .= \$_;
	    ";
	    eval $loop;
	    die $@ if $@;
	    #print STDERR "$TERM: $_\n--------\n";	# DEBUG
	    close TERMCAP;
	    # If :tc=...: found then search this file again
	    $entry =~ s/:tc=([^:]+):/:/ && ($TERM = $1, $state = 2);
	} while $state != 0;
    }
    die "Tgetent: Can't find $term\n" unless $entry ne '';
    $entry =~ s/:\s+:/:/g;
    $this->{TERMCAP} = $entry;
    #print STDERR $entry, "\n";				# DEBUG

    # Precompile $entry into the object
    foreach $field (split(/:[\s:\\]*/,$entry)) {
	if ($field =~ /^\w\w$/) {
	    $this->{'_' . $field} = 1 unless defined $this->{'_' . $1};
	}
	elsif ($field =~ /^(\w\w)\@/) {
	    $this->{'_' . $1} = "";
	}
	elsif ($field =~ /^(\w\w)#(.*)/) {
	    $this->{'_' . $1} = $2 unless defined $this->{'_' . $1};
	}
	elsif ($field =~ /^(\w\w)=(.*)/) {
	    next if defined $this->{'_' . ($cap = $1)};
	    $_ = $2;
	    s/\\E/\033/g;
	    s/\\(\d\d\d)/pack('c',oct($1) & 0177)/eg;
	    s/\\n/\n/g;
	    s/\\r/\r/g;
	    s/\\t/\t/g;
	    s/\\b/\b/g;
	    s/\\f/\f/g;
	    s/\\\^/\377/g;
	    s/\^\?/\177/g;
	    s/\^(.)/pack('c',ord($1) & 31)/eg;
	    s/\\(.)/$1/g;
	    s/\377/^/g;
	    $this->{'_' . $cap} = $_;
	}
	# else { warn "Tgetent: junk in $term: $field\n"; }
    }
    $this->{'_pc'} = "\0" unless defined $this->{'_pc'};
    $this->{'_bc'} = "\b" unless defined $this->{'_bc'};
    $this;
}

# delays for old style speeds
@Tpad = (0,200,133.3,90.9,74.3,66.7,50,33.3,16.7,8.3,5.5,4.1,2,1,.5,.2);

# $term->Tpad($string, $cnt, $FH);
sub Tpad {
    local($this, $string, $cnt, $FH) = @_;
    local($decr, $ms);

    if ($string =~ /(^[\d.]+)(\*?)(.*)$/) {
	$ms = $1;
	$ms *= $cnt if $2;
	$string = $3;
	$decr = $this->{OSPEED} < 50 ? $Tpad[$this->{OSPEED}] : $this->{DECR};
	if ($decr > .1) {
	    $ms += $decr / 2;
	    $string .= $this->{'_pc'} x ($ms / $decr);
	}
    }
    print $FH $string if $FH;
    $string;
}

# $term->Tputs($cap, $cnt, $FH);
sub Tputs {
    local($this, $cap, $cnt, $FH) = @_;
    local $string;

    if ($cnt > 1) {
	$string = Tpad($this, $this->{'_' . $cap}, $cnt);
    } else {
	$string = defined $this->{$cap} ? $this->{$cap} :
	    ($this->{$cap} = Tpad($this, $this->{'_' . $cap}, 1));
    }
    print $FH $string if $FH;
    $string;
}

# %%   output `%'
# %d   output value as in printf %d
# %2   output value as in printf %2d
# %3   output value as in printf %3d
# %.   output value as in printf %c
# %+x  add x to value, then do %.
#
# %>xy if value > x then add y, no output
# %r   reverse order of two parameters, no output
# %i   increment by one, no output
# %B   BCD (16*(value/10)) + (value%10), no output
#
# %n   exclusive-or all parameters with 0140 (Datamedia 2500)
# %D   Reverse coding (value - 2*(value%16)), no output (Delta Data)
#
# $term->Tgoto($cap, $col, $row, $FH);
sub Tgoto {
    local($this, $cap, $code, $tmp, $FH) = @_;
    local $string = $this->{'_' . $cap};
    local $result = '';
    local $after = '';
    local $online = 0;
    local @tmp = ($tmp,$code);
    local $cnt = $code;

    while ($string =~ /^([^%]*)%(.)(.*)/) {
	$result .= $1;
	$code = $2;
	$string = $3;
	if ($code eq 'd') {
	    $result .= sprintf("%d",shift(@tmp));
	}
	elsif ($code eq '.') {
	    $tmp = shift(@tmp);
	    if ($tmp == 0 || $tmp == 4 || $tmp == 10) {
		if ($online) {
		    ++$tmp, $after .= $this->{'_up'} if $this->{'_up'};
		}
		else {
		    ++$tmp, $after .= $this->{'_bc'};
		}
	    }
	    $result .= sprintf("%c",$tmp);
	    $online = !$online;
	}
	elsif ($code eq '+') {
	    $result .= sprintf("%c",shift(@tmp)+ord($string));
	    $string = substr($string,1,99);
	    $online = !$online;
	}
	elsif ($code eq 'r') {
	    ($code,$tmp) = @tmp;
	    @tmp = ($tmp,$code);
	    $online = !$online;
	}
	elsif ($code eq '>') {
	    ($code,$tmp,$string) = unpack("CCa99",$string);
	    if ($tmp[$[] > $code) {
		$tmp[$[] += $tmp;
	    }
	}
	elsif ($code eq '2') {
	    $result .= sprintf("%02d",shift(@tmp));
	    $online = !$online;
	}
	elsif ($code eq '3') {
	    $result .= sprintf("%03d",shift(@tmp));
	    $online = !$online;
	}
	elsif ($code eq 'i') {
	    ($code,$tmp) = @tmp;
	    @tmp = ($code+1,$tmp+1);
	}
	else {
	    return "OOPS";
	}
    }
    $string = Tpad($this, $result . $string . $after, $cnt);
    print $FH $string if $FH;
    $string;
}

# $this->Trequire($cap1, $cap2, ...);
sub Trequire {
    local $this = shift;
    local $_;
    foreach (@_) {
	die "Trequire: Terminal does not support: $_\n"
	    unless defined $this->{'_' . $_} && $this->{'_' . $_};
    }
}

1;
