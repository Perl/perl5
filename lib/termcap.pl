;# $Header: termcap.pl,v 3.0 89/10/18 15:19:58 lwall Locked $
;#
;# Usage:
;#	do 'ioctl.pl';
;#	ioctl(TTY,$TIOCGETP,$foo);
;#	($ispeed,$ospeed) = unpack('cc',$foo);
;#	do 'termcap.pl';
;#	do Tgetent('vt100');	# sets $TC{'cm'}, etc.
;#	do Tgoto($TC{'cm'},$row,$col);
;#	do Tputs($TC{'dl'},$affcnt,'FILEHANDLE');
;#
sub Tgetent {
    local($TERM) = @_;
    local($TERMCAP,$_,$entry,$loop,$field);

    warn "Tgetent: no ospeed set" unless $ospeed;
    foreach $key (keys(TC)) {
	delete $TC{$key};
    }
    $TERM = $ENV{'TERM'} unless $TERM;
    $TERMCAP = $ENV{'TERMCAP'};
    $TERMCAP = '/etc/termcap' unless $TERMCAP;
    if ($TERMCAP !~ m:^/:) {
	if (index($TERMCAP,"|$TERM|") < $[) {
	    $TERMCAP = '/etc/termcap';
	}
    }
    if ($TERMCAP =~ m:^/:) {
	$entry = '';
	do {
	    $loop = "
	    open(TERMCAP,'<$TERMCAP') || die \"Can't open $TERMCAP\";
	    while (<TERMCAP>) {
		next if /^#/;
		next if /^\t/;
		if (/\\|$TERM[:\\|]/) {
		    chop;
		    while (chop eq '\\\\') {
			\$_ .= <TERMCAP>;
			chop;
		    }
		    \$_ .= ':';
		    last;
		}
	    }
	    close TERMCAP;
	    \$entry .= \$_;
	    ";
	    eval $loop;
	} while s/:tc=([^:]+):/:/, $TERM = $1;
	$TERMCAP = $entry;
    }

    foreach $field (split(/:[\s:\\]*/,$TERMCAP)) {
	if ($field =~ /^\w\w$/) {
	    $TC{$field} = 1;
	}
	elsif ($field =~ /^(\w\w)#(.*)/) {
	    $TC{$1} = $2 if $TC{$1} eq '';
	}
	elsif ($field =~ /^(\w\w)=(.*)/) {
	    $entry = $1;
	    $_ = $2;
	    s/\\E/\033/g;
	    s/\\(\d\d\d)/pack('c',$1 & 0177)/eg;
	    s/\\n/\n/g;
	    s/\\r/\r/g;
	    s/\\t/\t/g;
	    s/\\b/\b/g;
	    s/\\f/\f/g;
	    s/\\\^/\377/g;
	    s/\^\?/\177/g;
	    s/\^(.)/pack('c',$1 & 031)/eg;
	    s/\\(.)/$1/g;
	    s/\377/^/g;
	    $TC{$entry} = $_ if $TC{$entry} eq '';
	}
    }
    $TC{'pc'} = "\0" if $TC{'pc'} eq '';
    $TC{'bc'} = "\b" if $TC{'bc'} eq '';
}

@Tputs = (0,200,133.3,90.9,74.3,66.7,50,33.3,16.7,8.3,5.5,4.1,2,1,.5,.2);

sub Tputs {
    local($string,$affcnt,$FH) = @_;
    local($ms);
    if ($string =~ /(^[\d.]+)(\*?)(.*)$/) {
	$ms = $1;
	$ms *= $affcnt if $2;
	$string = $3;
	$decr = $Tputs[$ospeed];
	if ($decr > .1) {
	    $ms += $decr / 2;
	    $string .= $TC{'pc'} x ($ms / $decr);
	}
    }
    print $FH $string if $FH;
    $string;
}

sub Tgoto {
    local($string) = shift(@_);
    local($result) = '';
    local($after) = '';
    local($code,$tmp) = @_;
    @_ = ($tmp,$code);
    local($online) = 0;
    while ($string =~ /^([^%]*)%(.)(.*)/) {
	$result .= $1;
	$code = $2;
	$string = $3;
	if ($code eq 'd') {
	    $result .= sprintf("%d",shift(@_));
	}
	elsif ($code eq '.') {
	    $tmp = shift(@_);
	    if ($tmp == 0 || $tmp == 4 || $tmp == 10) {
		if ($online) {
		    ++$tmp, $after .= $TC{'up'} if $TC{'up'};
		}
		else {
		    ++$tmp, $after .= $TC{'bc'};
		}
	    }
	    $result .= sprintf("%c",$tmp);
	    $online = !$online;
	}
	elsif ($code eq '+') {
	    $result .= sprintf("%c",shift(@_)+ord($string));
	    $string = substr($string,1,99);
	    $online = !$online;
	}
	elsif ($code eq 'r') {
	    ($code,$tmp) = @_;
	    @_ = ($tmp,$code);
	    $online = !$online;
	}
	elsif ($code eq '>') {
	    ($code,$tmp,$string) = unpack("CCa99",$string);
	    if ($_[$[] > $code) {
		$_[$[] += $tmp;
	    }
	}
	elsif ($code eq '2') {
	    $result .= sprintf("%02d",shift(@_));
	    $online = !$online;
	}
	elsif ($code eq '3') {
	    $result .= sprintf("%03d",shift(@_));
	    $online = !$online;
	}
	elsif ($code eq 'i') {
	    ($code,$tmp) = @_;
	    @_ = ($code+1,$tmp+1);
	}
	else {
	    return "OOPS";
	}
    }
    $result . $string . $after;
}

1;
