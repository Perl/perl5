package base;

use vars qw($VERSION);
$VERSION = '2.01';

# constant.pm is slow
sub SUCCESS () { 1 }

sub PUBLIC     () { 2**0  }
sub PRIVATE    () { 2**1  }
sub INHERITED  () { 2**2  }
sub PROTECTED  () { 2**3  }


my $Fattr = \%fields::attr;

sub has_fields {
    my($base) = shift;
    my $fglob = ${"$base\::"}{FIELDS};
    return $fglob && *$fglob{HASH};
}

sub has_version {
    my($base) = shift;
    my $vglob = ${$base.'::'}{VERSION};
    return $vglob && *$vglob{SCALAR};
}

sub has_attr {
    my($proto) = shift;
    my($class) = ref $proto || $proto;
    return exists $Fattr->{$class};
}

sub get_attr {
    $Fattr->{$_[0]} = [1] unless $Fattr->{$_[0]};
    return $Fattr->{$_[0]};
}

sub get_fields {
    # Shut up a possible typo warning.
    () = \%{$_[0].'::FIELDS'};

    return \%{$_[0].'::FIELDS'};
}

sub show_fields {
    my($base, $mask) = @_;
    my $fields = \%{$base.'::FIELDS'};
    return grep { ($Fattr->{$base}[$fields->{$_}] & $mask) == $mask} 
                keys %$fields;
}


sub import {
    my $class = shift;

    return SUCCESS unless @_;

    # List of base classes from which we will inherit %FIELDS.
    my $fields_base;

    my $inheritor = caller(0);

    foreach my $base (@_) {
        next if $inheritor->isa($base);

        if (has_version($base)) {
	    ${$base.'::VERSION'} = '-1, set by base.pm' 
	      unless defined ${$base.'::VERSION'};
        }
        else {
            local $SIG{__DIE__} = 'IGNORE';
            eval "require $base";
            # Only ignore "Can't locate" errors from our eval require.
            # Other fatal errors (syntax etc) must be reported.
            die if $@ && $@ !~ /^Can't locate .*? at \(eval /;
            unless (%{"$base\::"}) {
                require Carp;
                Carp::croak(<<ERROR);
Base class package "$base" is empty.
    (Perhaps you need to 'use' the module which defines that package first.)
ERROR

            }
            ${$base.'::VERSION'} = "-1, set by base.pm"
              unless defined ${$base.'::VERSION'};
        }
        push @{"$inheritor\::ISA"}, $base;

        # A simple test like (defined %{"$base\::FIELDS"}) will
        # sometimes produce typo warnings because it would create
        # the hash if it was not present before.
        #
        # We don't just check to see if the base in question has %FIELDS
        # defined, we also check to see if it has -inheritable- fields.
        # Its perfectly alright to inherit from multiple classes that have 
        # %FIELDS as long as only one of them has fields to give.
        if ( has_fields($base) || has_attr($base) ) {
	    # Check to see if there are fields to be inherited.
	    if ( show_fields($base, PUBLIC) or
                 show_fields($base, PROTECTED) ) {
		# No multiple fields inheritence *suck*
		if ($fields_base) {
		    require Carp;
		    Carp::croak("Can't multiply inherit %FIELDS");
		} else {
		    $fields_base = $base;
		}
	    }
        }
    }

    if( defined $fields_base ) {
        inherit_fields($inheritor, $fields_base);
    }
}


sub inherit_fields {
    my($derived, $base) = @_;

    return SUCCESS unless $base;

    my $battr = get_attr($base);
    my $dattr = get_attr($derived);
    my $dfields = get_fields($derived);
    my $bfields = get_fields($base);

    $dattr->[0] = @$battr;

    if( keys %$dfields ) {
        warn "$derived is inheriting from $base but already has its own ".
             "fields!\n".
             "This will cause problems with pseudo-hashes.\n".
             "Be sure you use base BEFORE declaring fields\n";
    }

    # Iterate through the base's fields adding all the non-private
    # ones to the derived class.  Hang on to the original attribute
    # (Public, Private, etc...) and add Inherited.
    # This is all too complicated to do efficiently with add_fields().
    while (my($k,$v) = each %$bfields) {
        my $fno;
	if ($fno = $dfields->{$k} and $fno != $v) {
	    require Carp;
	    Carp::croak ("Inherited %FIELDS can't override existing %FIELDS");
	}

        if( $battr->[$v] & PRIVATE ) {
            $dattr->[$v] = undef;
        }
        else {
            $dattr->[$v] = INHERITED | $battr->[$v];

            # Derived fields must be kept in the same position as the
            # base in order to make "static" typing work with psuedo-hashes.
            # Alas, this kills multiple field inheritance.
            $dfields->{$k} = $v;
        }
    }
}


1;

__END__

=head1 NAME

base - Establish IS-A relationship with base class at compile time

=head1 SYNOPSIS

    package Baz;
    use base qw(Foo Bar);

=head1 DESCRIPTION

Roughly similar in effect to

    BEGIN {
        require Foo;
        require Bar;
        push @ISA, qw(Foo Bar);
    }

Will also initialize the fields if one of the base classes has it.
Multiple Inheritence of fields is B<NOT> supported, if two or more
base classes each have inheritable fields the 'base' pragma will
croak.  See L<fields>, L<public> and L<protected> for a description of
this feature.

When strict 'vars' is in scope, I<base> also lets you assign to @ISA
without having to declare @ISA with the 'vars' pragma first.

If any of the base classes are not loaded yet, I<base> silently
C<require>s them (but it won't call the C<import> method).  Whether to
C<require> a base class package is determined by the absence of a global
$VERSION in the base package.  If $VERSION is not detected even after
loading it, I<base> will define $VERSION in the base package, setting it to
the string C<-1, set by base.pm>.


=head1 HISTORY

This module was introduced with Perl 5.004_04.


=head1 CAVEATS

Due to the limitations of the pseudo-hash implementation, you must use
base I<before> you declare any of your own fields.


=head1 SEE ALSO

L<fields>

=cut
