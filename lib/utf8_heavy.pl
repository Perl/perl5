package utf8;
use strict;
use warnings;

sub DEBUG () { 0 }

sub DESTROY {}

sub croak { require Carp; Carp::croak(@_) }

sub SWASHNEW {
    my ($class, $type, $list, $minbits, $none) = @_;
    local $^D = 0 if $^D;

    print STDERR "SWASHNEW @_\n" if DEBUG;

    ## check to see if we've already got it.
    {
        no strict 'refs';
        if ($type and ref ${"${class}::{$type}"} eq $class) {
            warn qq/Found \${"${class}::{$type}"}\n/ if DEBUG;
            return ${"${class}::{$type}"};
        }
    }

    ##
    ## Get the list of codepoints for the type.
    ## Called from utf8.c
    ##
    ## Given a $type, our goal is to fill $list with the set of codepoint
    ## ranges. As we try various interpretations of $type, sometimes we'll
    ## end up with the $list directly, and sometimes we'll end up with a
    ## $file name that holds the list data.
    ##
    ## To make the parsing of $type clear, this code takes the a rather
    ## unorthadox approach of last'ing out of the block once we have the
    ## info we need. Were this to be a subroutine, the 'last' would just
    ## be a 'return'.
    ##
    if ($type)
    {
        $type =~ s/^\s+//;
        $type =~ s/\s+$//;

        print "type = $type\n" if DEBUG;

        my $file;
        ## Figure out what file to load to get the data....
      GETFILE:
        {
            ##
            ## First, see if it's an "Is" name (the 'Is' is optional)
            ##
            ## Because we check "Is" names first, they have precidence over
            ## "In" names. For example, "Greek" is both a script and a
            ## block. "IsGreek" always gets the script, while "InGreek"
            ## always gets the block. "Greek" gets the script because we
            ## check "Is" names first.
            ##
            if ($type =~ m{^
                           ## "Is" prefix, or "Script=" or "Category="
                           (?: Is [- _]? | (?:Script|Category)\s*=\s* )?
                           ## name to check in the "Is" symbol table.
                           ([A-Z].*)
                           $
                          }ix)
            {
                my $istype = $1;
                ##
                ## Input ($type)     Name To Check ($istype)
                ## -------------     -----------------------
                ## IsLu                 Lu
                ## Lu                   Lu
                ## Category = Lu        Lu
                ## Foo                  Foo
                ## Script = Greek       Greek
                ##

                print "istype = $istype\n" if DEBUG;

                ## Load "Is" mapping data, if not yet loaded.
                do "unicore/Is.pl" if not defined %utf8::Is;

                ##
                ## If the "Is" mapping data has an exact match, it points
                ## to the file we need.
                ##
                if (exists $utf8::Is{$istype})
                {
                    $file = "unicore/Is/$utf8::Is{$istype}.pl";
                    last GETFILE;
                }

                ##
                ## Need to look at %utf8::IsPat (loaded from "unicore/Is.pl")
                ## to see if there's a regex that matches this $istype.
                ## If so, the associated name is the file we need.
                ##
                my $prefix = substr(lc($istype), 0, 2);
                if (my $hashref = $utf8::IsPat{$prefix})
                {
                    while (my ($pat, $name) = each %{$hashref})
                    {
                        print "isprefix = $prefix, Is = $istype, pat = $pat\n" if DEBUG;
                        ##
                        ## The following regex probably need not be cached,
                        ## since every time there's a match, the results of
                        ## the entire call to SWASHNEW() is cached, so there's
                        ## a very limited number of times any one $pat will
                        ## be evaluated as a regex, at least with "reasonable"
                        ## code that doesn't try a baziilion \p{Random} names.
                        ##
                        if ($istype =~ /^$pat$/i)
                        {
                            $file = "unicore/Is/$name.pl";
                            keys %{$hashref}; ## reset the 'each' above
                            last GETFILE;
                        }
                    }
                }
            }

            ##
            ## Couldn't find via "Is" -- let's try via "In".....
            ##
            if ($type =~ m{^
                           ( In(?!herited$)[- _]? | Block\s*=\s*)?
                           ([A-Z].*)
                           $
                          }xi)
            {
                my $intype = $2;
                print "intype = $intype\n" if DEBUG;

                ##
                ## Input ($type)      Name To Check ($intype)
                ## -------------      -----------------------
                ## Inherited             Inherited
                ## InGreek               Greek
                ## Block = Greek         Greek
                ##

                ## Load "In" mapping data, if not yet loaded.
                do "unicore/In.pl" if not defined %utf8::In;

                ## If there's a direct match, it points to the file we need
                if (exists $utf8::In{$intype}) {
                    $file = "unicore/In/$utf8::In{$intype}.pl";
                    last GETFILE;
                }

                ##
                ## Need to look at %utf8::InPat (loaded from "unicore/In.pl")
                ## to see if there's a regex that matches this $intype.
                ## If so, the associated name is the file we need.
                ##
                my $prefix = substr(lc($intype), 0, 2);
                if (my $hashref = $utf8::InPat{$prefix})
                {
                    print "inprefix = $prefix, In = $intype\n" if DEBUG;
                    while (my ($pat, $name) = each %{$hashref})
                    {
                        print "inprefix = $prefix, In = $intype, k = $pat\n" if DEBUG;
                        if ($intype =~ /^$pat$/i) {
                            $file = "unicore/In/$name.pl";
                            print "inprefix = $prefix, In = $intype, k = $pat, file = $file\n" if DEBUG;
                            keys %{$hashref}; ## reset the 'each' above
                            last GETFILE;
                        }
                    }
                }
            }

            ##
            ## Last attempt -- see if it's a "To" name (e.g. "ToLower")
            ##
            if ($type =~ /^To([A-Z][A-Za-z]+)$/)
            {
                $file = "unicore/To/$1.pl";
                ## would like to test to see if $file actually exists....
                last GETFILE;
            }

            ##
            ## If we reach this line, it's because we couldn't figure
            ## out what to do with $type. Ouch.
            ##
            croak("Can't find Unicode character property \"$type\"");
        }

        ##
        ## If we reach here, it was due to a 'last GETFILE' above, so we
        ## have a filename, so now we load it.
        ##
        $list = do $file;
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
	    print STDERR "$1 => $2\n" if DEBUG;
	    if ($char =~ /[-+!]/) {
		my ($c,$t) = split(/::/, $name, 2);	# bogus use of ::, really
		my $subobj = $c->SWASHNEW($t, "", 0, 0, 0);
		push @extras, $name => $subobj;
		$bits = $subobj->{BITS} if $bits < $subobj->{BITS};
	    }
	}
    }

    print STDERR "CLASS = $class, TYPE => $type, BITS => $bits, NONE => $none\nEXTRAS =>\n$extras\nLIST =>\n$list\n" if DEBUG;

    no strict 'refs';
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
    # See utf8.c:Perl_swash_fetch for problems with this interface.
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
		print "$min $max $val\n" if DEBUG;
		if ($none) {
		    if ($min < $start) {
			$val += $start - $min if $val < $none;
			$min = $start;
		    }
		    for ($key = $min; $key <= $max; $key++) {
			last LINE if $key >= $end;
			print STDERR "$key => $val\n" if DEBUG;
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
			print STDERR "$key => $val\n" if DEBUG;
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
		    print STDERR "$key => 1\n" if DEBUG;
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
