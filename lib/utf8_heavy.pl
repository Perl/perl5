package utf8;

sub DEBUG () { 0 }

sub DESTROY {}

sub croak { require Carp; Carp::croak(@_) }

sub SWASHNEW {
    my ($class, $type, $list, $minbits, $none) = @_;
    local $^D = 0 if $^D;

    print STDERR "SWASHNEW @_\n" if DEBUG;

    my $file;

    if ($type and ref ${"${class}::{$type}"} eq $class) {
	warn qq/Found \${"${class}::{$type}"}\n/ if DEBUG;
	return ${"${class}::{$type}"};	# Already there...
    }

    if ($type) {

	defined %utf8::In || do "unicore/In.pl";

	$type =~ s/^In(?:[-_]|\s+)?(?!herited$)//i;
	$type =~ s/\s+$//;

        $type = 'Lampersand' if $type =~ /^(?:Is)?L&$/;

	my $inprefix = substr(lc($type), 0, 3);
	if (exists $utf8::InPat{$inprefix}) {
	    my $In = $type;
	    for my $k (keys %{$utf8::InPat{$inprefix}}) {
		if ($In =~ /^$k$/i) {
		    $In = $utf8::InPat{$inprefix}->{$k};
		    if (exists $utf8::In{$In}) {
			$file = "unicore/In/$utf8::In{$In}";
			print "inprefix = $inprefix, In = $In, k = $k, file = $file\n" if DEBUG;
			last;
		    }
		}
	    }
	}

	unless (defined $file) {
	    # This is separate from 'To' in preparation of Is.pl (a la In.pl).
	    if ($type =~ /^Is([A-Z][A-Za-z]*)$/) {
		$file = "unicore/Is/$1";
	    } elsif ((not defined $file) && $type =~ /^To([A-Z][A-Za-z]*)$/) {
		$file = "unicore/To/$1";
	    }
	}
    }

    {
        $list ||= do "$file.pl"
	      ||  do "unicore/Is/$type.pl"
	      ||  croak("Can't find Unicode character property \"$type\"");
    }

    my $extras;
    my $bits;
 
    if ($list) {
	my @tmp = split(/^/m, $list);
	my %seen;
	no warnings;
	$extras = join '', grep /^[^0-9a-fA-F]/, @tmp;
	$list = join '',
	    sort { hex $a <=> hex $b }
	    grep {/^([0-9a-fA-F]+)/ and not $seen{$1}++} @tmp; # XXX doesn't do ranges right
    }

    if ($none) {
	my $hextra = sprintf "%04x", $none + 1;
	$list =~ s/\tXXXX$/\t$hextra/mg;
    }

    if ($minbits < 32) {
	my $top = 0;
	while ($list =~ /^([0-9a-fA-F]+)(?:\t([0-9a-fA-F]+)?)(?:\t([0-9a-fA-F]+))?/mg) {
	    my $min = hex $1;
	    my $max = hex(defined $2 ? $2 : $1);
	    my $val = hex(defined $3 ? $3 : "");
	    $val += $max - $min if defined $3;
	    $top = $val if $val > $top;
	}
	$bits =
	    $top > 0xffff ? 32 :
	    $top > 0xff ? 16 :
	    $top > 1 ? 8 : 1
    }
    $bits = $minbits if $bits < $minbits;

    my @extras;
    for my $x ($extras) {
	pos $x = 0;
	while ($x =~ /^([^0-9a-fA-F\n])(.*)/mg) {
	    my $char = $1;
	    my $name = $2;
#	    print STDERR "$1 => $2\n" if DEBUG;
	    if ($char =~ /[-+!]/) {
		my ($c,$t) = split(/::/, $name, 2);	# bogus use of ::, really
		my $subobj = $c->SWASHNEW($t, "", 0, 0, 0);
		push @extras, $name => $subobj;
		$bits = $subobj->{BITS} if $bits < $subobj->{BITS};
	    }
	}
    }

    print STDERR "CLASS = $class, TYPE => $type, BITS => $bits, NONE => $none\nEXTRAS =>\n$extras\nLIST =>\n$list\n" if DEBUG;

    ${"${class}::{$type}"} = bless {
	TYPE => $type,
	BITS => $bits,
	EXTRAS => $extras,
	LIST => $list,
	NONE => $none,
	@extras,
    } => $class;
}

# NOTE: utf8.c:swash_init() assumes entries are never modified once generated.

sub SWASHGET {
    my ($self, $start, $len) = @_;
    local $^D = 0 if $^D;
    my $type = $self->{TYPE};
    my $bits = $self->{BITS};
    my $none = $self->{NONE};
    print STDERR "SWASHGET @_ [$type/$bits/$none]\n" if DEBUG;
    my $end = $start + $len;
    my $swatch = "";
    my $key;
    vec($swatch, $len - 1, $bits) = 0;	# Extend to correct length.
    if ($none) {
	for $key (0 .. $len - 1) { vec($swatch, $key, $bits) = $none }
    }

    for ($self->{LIST}) {
	pos $_ = 0;
	if ($bits > 1) {
	  LINE:
	    while (/^([0-9a-fA-F]+)(?:\t([0-9a-fA-F]+)?)(?:\t([0-9a-fA-F]+))?/mg) {
		my $min = hex $1;
		my $max = (defined $2 ? hex $2 : $min);
		my $val = hex $3;
		next if $max < $start;
#		print "$min $max $val\n";
		if ($none) {
		    if ($min < $start) {
			$val += $start - $min if $val < $none;
			$min = $start;
		    }
		    for ($key = $min; $key <= $max; $key++) {
			last LINE if $key >= $end;
#			print STDERR "$key => $val\n" if DEBUG;
			vec($swatch, $key - $start, $bits) = $val;
			++$val if $val < $none;
		    }
		}
		else {
		    if ($min < $start) {
			$val += $start - $min;
			$min = $start;
		    }
		    for ($key = $min; $key <= $max; $key++, $val++) {
			last LINE if $key >= $end;
#			print STDERR "$key => $val\n" if DEBUG;
			vec($swatch, $key - $start, $bits) = $val;
		    }
		}
	    }
	}
	else {
	  LINE:
	    while (/^([0-9a-fA-F]+)(?:\t([0-9a-fA-F]+))?/mg) {
		my $min = hex $1;
		my $max = (defined $2 ? hex $2 : $min);
		next if $max < $start;
		if ($min < $start) {
		    $min = $start;
		}
		for ($key = $min; $key <= $max; $key++) {
		    last LINE if $key >= $end;
#		    print STDERR "$key => 1\n" if DEBUG;
		    vec($swatch, $key - $start, 1) = 1;
		}
	    }
	}
    }
    for my $x ($self->{EXTRAS}) {
	pos $x = 0;
	while ($x =~ /^([-+!])(.*)/mg) {
	    my $char = $1;
	    my $name = $2;
	    print STDERR "INDIRECT $1 $2\n" if DEBUG;
	    my $otherbits = $self->{$name}->{BITS};
	    croak("SWASHGET size mismatch") if $bits < $otherbits;
	    my $other = $self->{$name}->SWASHGET($start, $len);
	    if ($char eq '+') {
		if ($bits == 1 and $otherbits == 1) {
		    $swatch |= $other;
		}
		else {
		    for ($key = 0; $key < $len; $key++) {
			vec($swatch, $key, $bits) = vec($other, $key, $otherbits);
		    }
		}
	    }
	    elsif ($char eq '!') {
		if ($bits == 1 and $otherbits == 1) {
		    $swatch |= ~$other;
		}
		else {
		    for ($key = 0; $key < $len; $key++) {
			if (!vec($other, $key, $otherbits)) {
			    vec($swatch, $key, $bits) = 1;
			}
		    }
		}
	    }
	    elsif ($char eq '-') {
		if ($bits == 1 and $otherbits == 1) {
		    $swatch &= ~$other;
		}
		else {
		    for ($key = 0; $key < $len; $key++) {
			if (vec($other, $key, $otherbits)) {
			    vec($swatch, $key, $bits) = 0;
			}
		    }
		}
	    }
	}
    }
    if (DEBUG) {
	print STDERR "CELLS ";
	for ($key = 0; $key < $len; $key++) {
	    print STDERR vec($swatch, $key, $bits), " ";
	}
	print STDERR "\n";
    }
    $swatch;
}

1;
