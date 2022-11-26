use 5.008;
package base;

use strict 'vars';
our $VERSION = '2.27';
$VERSION =~ tr/_//d;

# simplest way to avoid indexing of the package: no package statement
sub base::__inc::unhook {
    if (UNIVERSAL::isa($_[0],"base::__inc::hidden_dot")) {
        @INC = map { (ref($_) && ($_ == $_[0])) ? "." : $_ } @INC;
    } else {
        @INC = grep { !ref($_) || ($_ != $_[0]) } @INC;
    }
}
# instance is blessed array of coderefs to be removed from @INC at scope exit
sub base::__inc::scope_guard::new {
    my ($class, @refs)= @_;
    return bless \@refs, $class;
}

sub base::__inc::scope_guard::DESTROY {
    for (@{$_[0]}) {
        if (UNIVERSAL::isa($_,"base::__inc::hidden_dot")) {
            pop @$_;
            base::__inc::unhook($_) unless @$_;
        } else {
            base::__inc::unhook($_);
        }
    }
}

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
    return( ($fglob && 'GLOB' eq ref($fglob) && *$fglob{HASH}) ? 1 : 0 );
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

if ($] < 5.009) {
    *get_fields = sub {
        # Shut up a possible typo warning.
        () = \%{$_[0].'::FIELDS'};
        my $f = \%{$_[0].'::FIELDS'};

        # should be centralized in fields? perhaps
        # fields::mk_FIELDS_be_OK. Peh. As long as %{ $package . '::FIELDS' }
        # is used here anyway, it doesn't matter.
        bless $f, 'pseudohash' if (ref($f) ne 'pseudohash');

        return $f;
    }
}
else {
    *get_fields = sub {
        # Shut up a possible typo warning.
        () = \%{$_[0].'::FIELDS'};
        return \%{$_[0].'::FIELDS'};
    }
}

if ($] < 5.008) {
    *_module_to_filename = sub {
        (my $fn = $_[0]) =~ s!::!/!g;
        $fn .= '.pm';
        return $fn;
    }
}
else {
    *_module_to_filename = sub {
        (my $fn = $_[0]) =~ s!::!/!g;
        $fn .= '.pm';
        utf8::encode($fn);
        return $fn;
    }
}

sub base::__inc::hidden_dot::new {
    my $class = shift;
    my $self= bless [], $class;
    $self->add_frame(@_) if @_;
    return $self;
}

sub base::__inc::hidden_dot::add_frame {
    my ($self, $rlevel, $rdot_hidden)= @_;
    push @$self, [$rlevel, $rdot_hidden];
    return $self;
}

sub base::__inc::hidden_dot::INCDIR {
    my $self= shift;
    my $frame= @$self ? $self->[-1] : undef;
    my ($rlevel,$rdot_hidden)= @{$frame||[]};
    if (@$self == 1) {
        $INC[$INC] = ".";
    }
    if (!$rlevel || defined(caller($$rlevel))) {
        return ".";
    }
    $$rdot_hidden = 1;
    return ();
}


sub import {
    my $class = shift;

    return SUCCESS unless @_;

    # List of base classes from which we will inherit %FIELDS.
    my $fields_base;

    my $inheritor = caller(0);

    my @bases;
    foreach my $base (@_) {
        if ( $inheritor eq $base ) {
            warn "Class '$inheritor' tried to inherit from itself\n";
        }

        next if grep $_->isa($base), ($inheritor, @bases);

        # Following blocks help isolate $SIG{__DIE__} and @INC changes
        {
            my $sigdie;
            {
                local $SIG{__DIE__};
                my $fn = _module_to_filename($base);
                my $dot_hidden;
                eval {
                    my $guard;
                    if (@INC and %{"$base\::"}) {
                        # So:  the package already exists   => this an optional load
                        # And: there is a dot at the end of @INC  => we want to hide it
                        # However: we only want to hide it during our *own* require()
                        # (i.e. without affecting nested require()s).
                        #
                        # So we replace the dot with an object that supports an INCDIR
                        # method that can hide or reveal the dot as necessary. This
                        # INCDIR method needs to know the callstack depth at which it
                        # should return an empty list.
                        #
                        # Since people can override CORE::GLOBAL::require we cannot
                        # determine in advance what the exact relevant callstack depth will
                        # be and so we have to record it inside a hook. So we put another
                        # hook (a closure) just for that at the front of @INC, where it's
                        # guaranteed to run -- immediately. It runs and sets the level var
                        # $lvl that will be used by the INCDIR method and then removes itself
                        # from @INC immediately.
                        #
                        # The INCDIR hook needs to be able to share state with the callback
                        # that determines the level, we achieve this by keeping a stack of
                        # frames with a reference to the $lvl var set above, and to the $dot_hidden.
                        # When the incdir method is called it checks the topmost frame it
                        # contains, and uses that to determine if it must return a "." or
                        # an empty list. When the require is completed that frame is popped
                        # out of the object. When the object is empty it replaces itself in
                        # INC with ".". Should the hook return () it also sets its reference
                        # to $dot_hidden to true, so that we return the right error message.
                        #
                        # We use a scope guard to ensure that the frames are removed from the
                        # hidden dot object, or that the object is replaced with a dot.
                        if ($INC[-1] eq ".") {
                            $INC[-1] = base::__inc::hidden_dot->new();
                        }
                        if (UNIVERSAL::isa($INC[-1],"base::__inc::hidden_dot")) {
                            my $lvl;
                            unshift @INC, sub {
                                1 while defined caller ++$lvl; # compute frame for current call
                                shift @INC;  # remove this sub from @INC
                                undef $INC;  # and restart @INC search at the start.
                                ();
                            };
                            $INC[-1]->add_frame(\$lvl,\$dot_hidden); # add this frame
                            $guard = base::__inc::scope_guard->new(@INC[0,-1]);
                        }
                    }
                    require $fn
                };
                if ($dot_hidden && (my @fn = grep -e && !( -d _ || -b _ ), $fn.'c', $fn)) {
                    require Carp;
                    Carp::croak(<<ERROR);
Base class package "$base" is not empty but "$fn[0]" exists in the current directory.
    To help avoid security issues, base.pm now refuses to load optional modules
    from the current working directory when it is the last entry in \@INC.
    If your software worked on previous versions of Perl, the best solution
    is to use FindBin to detect the path properly and to add that path to
    \@INC.  As a last resort, you can re-enable looking in the current working
    directory by adding "use lib '.'" to your code.
ERROR
                }
                # Only ignore "Can't locate" errors from our eval require.
                # Other fatal errors (syntax etc) must be reported.
                #
                # changing the check here is fragile - if the check
                # here isn't catching every error you want, you should
                # probably be using parent.pm, which doesn't try to
                # guess whether require is needed or failed,
                # see [perl #118561]
                die if $@ && $@ !~ /^Can't locate \Q$fn\E .*? at .* line [0-9]+(?:, <[^>]*> (?:line|chunk) [0-9]+)?\.\n\z/s
                          || $@ =~ /Compilation failed in require at .* line [0-9]+(?:, <[^>]*> (?:line|chunk) [0-9]+)?\.\n\z/;
                unless (%{"$base\::"}) {
                    require Carp;
                    local $" = " ";
                    Carp::croak(<<ERROR);
Base class package "$base" is empty.
    (Perhaps you need to 'use' the module which defines that package first,
    or make that module available in \@INC (\@INC contains: @INC).
ERROR
                }
                $sigdie = $SIG{__DIE__} || undef;
            }
            # Make sure a global $SIG{__DIE__} makes it out of the localization.
            $SIG{__DIE__} = $sigdie if defined $sigdie;
        }
        push @bases, $base;

        if ( has_fields($base) || has_attr($base) ) {
            # No multiple fields inheritance *suck*
            if ($fields_base) {
                require Carp;
                Carp::croak("Can't multiply inherit fields");
            } else {
                $fields_base = $base;
            }
        }
    }
    # Save this until the end so it's all or nothing if the above loop croaks.
    push @{"$inheritor\::ISA"}, @bases;

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
        warn <<"END";
$derived is inheriting from $base but already has its own fields!
This will cause problems.  Be sure you use base BEFORE declaring fields.
END

    }

    # Iterate through the base's fields adding all the non-private
    # ones to the derived class.  Hang on to the original attribute
    # (Public, Private, etc...) and add Inherited.
    # This is all too complicated to do efficiently with add_fields().
    while (my($k,$v) = each %$bfields) {
        my $fno;
        if ($fno = $dfields->{$k} and $fno != $v) {
            require Carp;
            Carp::croak ("Inherited fields can't override existing fields");
        }

        if( $battr->[$v] & PRIVATE ) {
            $dattr->[$v] = PRIVATE | INHERITED;
        }
        else {
            $dattr->[$v] = INHERITED | $battr->[$v];
            $dfields->{$k} = $v;
        }
    }

    foreach my $idx (1..$#{$battr}) {
        next if defined $dattr->[$idx];
        $dattr->[$idx] = $battr->[$idx] & INHERITED;
    }
}


1;

__END__

=head1 NAME

base - Establish an ISA relationship with base classes at compile time

=head1 SYNOPSIS

    package Baz;
    use base qw(Foo Bar);

=head1 DESCRIPTION

Unless you are using the C<fields> pragma, consider this module discouraged
in favor of the lighter-weight C<parent>.

Allows you to both load one or more modules, while setting up inheritance from
those modules at the same time.  Roughly similar in effect to

    package Baz;
    BEGIN {
        require Foo;
        require Bar;
        push @ISA, qw(Foo Bar);
    }

When C<base> tries to C<require> a module, it will not die if it cannot find
the module's file, but will die on any other error.  After all this, should
your base class be empty, containing no symbols, C<base> will die. This is
useful for inheriting from classes in the same file as yourself but where
the filename does not match the base module name, like so:

        # in Bar.pm
        package Foo;
        sub exclaim { "I can have such a thing?!" }

        package Bar;
        use base "Foo";

There is no F<Foo.pm>, but because C<Foo> defines a symbol (the C<exclaim>
subroutine), C<base> will not die when the C<require> fails to load F<Foo.pm>.

C<base> will also initialize the fields if one of the base classes has it.
Multiple inheritance of fields is B<NOT> supported, if two or more base classes
each have inheritable fields the 'base' pragma will croak. See L<fields>
for a description of this feature.

The base class' C<import> method is B<not> called.


=head1 DIAGNOSTICS

=over 4

=item Base class package "%s" is empty.

base.pm was unable to require the base package, because it was not
found in your path.

=item Class 'Foo' tried to inherit from itself

Attempting to inherit from yourself generates a warning.

    package Foo;
    use base 'Foo';

=back

=head1 HISTORY

This module was introduced with Perl 5.004_04.

=head1 CAVEATS

Due to the limitations of the implementation, you must use
base I<before> you declare any of your own fields.


=head1 SEE ALSO

L<fields>

=cut
