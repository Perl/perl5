package constant;

use strict;
use 5.006_00;
use warnings::register;

our($VERSION, %declared);
$VERSION = '1.04';

#=======================================================================

# Some names are evil choices.
my %keywords = map +($_, 1), qw{ BEGIN INIT CHECK END DESTROY AUTOLOAD };

my %forced_into_main = map +($_, 1),
    qw{ STDIN STDOUT STDERR ARGV ARGVOUT ENV INC SIG };

my %forbidden = (%keywords, %forced_into_main);

#=======================================================================
# import() - import symbols into user's namespace
#
# What we actually do is define a function in the caller's namespace
# which returns the value. The function we create will normally
# be inlined as a constant, thereby avoiding further sub calling 
# overhead.
#=======================================================================
sub import {
    my $class = shift;
    return unless @_;			# Ignore 'use constant;'
    my %constants = ();
    my $multiple  = ref $_[0];

    if ( $multiple ) {
	if (ref $_[0] ne 'HASH') {
	    require Carp;
	    Carp::croak("Invalid reference type '".ref(shift)."' not 'HASH'");
	}
	%constants = %{+shift};
    } else {
	$constants{+shift} = undef;
    }

    foreach my $name ( keys %constants ) {
	unless (defined $name) {
	    require Carp;
	    Carp::croak("Can't use undef as constant name");
	}
	my $pkg = caller;

	# Normal constant name
	if ($name =~ /^_?[^\W_0-9]\w*\z/ and !$forbidden{$name}) {
	    # Everything is okay

	# Name forced into main, but we're not in main. Fatal.
	} elsif ($forced_into_main{$name} and $pkg ne 'main') {
	    require Carp;
	    Carp::croak("Constant name '$name' is forced into main::");

	# Starts with double underscore. Fatal.
	} elsif ($name =~ /^__/) {
	    require Carp;
	    Carp::croak("Constant name '$name' begins with '__'");

	# Maybe the name is tolerable
	} elsif ($name =~ /^[A-Za-z_]\w*\z/) {
	    # Then we'll warn only if you've asked for warnings
	    if (warnings::enabled()) {
		if ($keywords{$name}) {
		    warnings::warn("Constant name '$name' is a Perl keyword");
		} elsif ($forced_into_main{$name}) {
		    warnings::warn("Constant name '$name' is " .
			"forced into package main::");
		} else {
		    # Catch-all - what did I miss? If you get this error,
		    # please let me know what your constant's name was.
		    # Write to <rootbeer@redcat.com>. Thanks!
		    warnings::warn("Constant name '$name' has unknown problems");
		}
	    }

	# Looks like a boolean
	# use constant FRED == fred;
	} elsif ($name =~ /^[01]?\z/) {
            require Carp;
	    if (@_) {
		Carp::croak("Constant name '$name' is invalid");
	    } else {
		Carp::croak("Constant name looks like boolean value");
	    }

	} else {
	   # Must have bad characters
            require Carp;
	    Carp::croak("Constant name '$name' has invalid characters");
	}

	{
	    no strict 'refs';
	    my $full_name = "${pkg}::$name";
	    $declared{$full_name}++;
	    if ($multiple) {
		my $scalar = $constants{$name};
		*$full_name = sub () { $scalar };
	    } else {
		if (@_ == 1) {
		    my $scalar = $_[0];
		    *$full_name = sub () { $scalar };
		} elsif (@_) {
		    my @list = @_;
		    *$full_name = sub () { @list };
		} else {
		    *$full_name = sub () { };
		}
	    }
	}
    }
}

1;

__END__

=head1 NAME

constant - Perl pragma to declare constants

=head1 SYNOPSIS

    use constant BUFFER_SIZE	=> 4096;
    use constant ONE_YEAR	=> 365.2425 * 24 * 60 * 60;
    use constant PI		=> 4 * atan2 1, 1;
    use constant DEBUGGING	=> 0;
    use constant ORACLE		=> 'oracle@cs.indiana.edu';
    use constant USERNAME	=> scalar getpwuid($<);
    use constant USERINFO	=> getpwuid($<);

    sub deg2rad { PI * $_[0] / 180 }

    print "This line does nothing"		unless DEBUGGING;

    # references can be constants
    use constant CHASH		=> { foo => 42 };
    use constant CARRAY		=> [ 1,2,3,4 ];
    use constant CPSEUDOHASH	=> [ { foo => 1}, 42 ];
    use constant CCODE		=> sub { "bite $_[0]\n" };

    print CHASH->{foo};
    print CARRAY->[$i];
    print CPSEUDOHASH->{foo};
    print CCODE->("me");
    print CHASH->[10];			# compile-time error

    # declaring multiple constants at once
    use constant {
	BUFFER_SIZE	=> 4096,
	ONE_YEAR	=> 365.2425 * 24 * 60 * 60,
	PI		=> 4 * atan2( 1, 1 ),
	DEBUGGING	=> 0,
	ORACLE		=> 'oracle@cs.indiana.edu',
	USERNAME	=> scalar getpwuid($<),      # this works
	USERINFO	=> getpwuid($<),             # THIS IS A BUG!
    };

=head1 DESCRIPTION

This will declare a symbol to be a constant with the given scalar
or list value.

When you declare a constant such as C<PI> using the method shown
above, each machine your script runs upon can have as many digits
of accuracy as it can use. Also, your program will be easier to
read, more likely to be maintained (and maintained correctly), and
far less likely to send a space probe to the wrong planet because
nobody noticed the one equation in which you wrote C<3.14195>.

=head1 NOTES

The value or values are evaluated in a list context. You may override
this with C<scalar> as shown above.

These constants do not directly interpolate into double-quotish
strings, although you may do so indirectly. (See L<perlref> for
details about how this works.)

    print "The value of PI is @{[ PI ]}.\n";

List constants are returned as lists, not as arrays.

    $homedir = USERINFO[7];		# WRONG
    $homedir = (USERINFO)[7];		# Right

The use of all caps for constant names is merely a convention,
although it is recommended in order to make constants stand out
and to help avoid collisions with other barewords, keywords, and
subroutine names. Constant names must begin with a letter or
underscore. Names beginning with a double underscore are reserved. Some
poor choices for names will generate warnings, if warnings are enabled at
compile time.

Constant symbols are package scoped (rather than block scoped, as
C<use strict> is). That is, you can refer to a constant from package
Other as C<Other::CONST>.  You may also use constants as either class
or object methods, ie. C<< Other->CONST() >> or C<< $obj->CONST() >>.
Such constant methods will be inherited as usual.

As with all C<use> directives, defining a constant happens at
compile time. Thus, it's probably not correct to put a constant
declaration inside of a conditional statement (like C<if ($foo)
{ use constant ... }>).  When defining multiple constants, you
cannot use the values of other constants within the same declaration
scope.  This is because the calling package doesn't know about any
constant within that group until I<after> the C<use> statement is
finished.

    use constant {
	AGE    => 20,
	PERSON => { age => AGE }, # Error!
    };
    [...]
    use constant PERSON => { age => AGE }; # Right

Giving an empty list, C<()>, as the value for a symbol makes it return
C<undef> in scalar context and the empty list in list context.

    use constant UNICORNS => ();

    print "Impossible!\n"  if defined UNICORNS;    
    my @unicorns = UNICORNS;  # there are no unicorns

The same effect can be achieved by omitting the value and the big
arrow entirely, but then the symbol name must be put in quotes.

    use constant "UNICORNS";

The result from evaluating a list constant with more than one element
in a scalar context is not documented, and is B<not> guaranteed to be
any particular value in the future. In particular, you should not rely
upon it being the number of elements in the list, especially since it
is not B<necessarily> that value in the current implementation.

Magical values and references can be made into constants at compile
time, allowing for way cool stuff like this.  (These error numbers
aren't totally portable, alas.)

    use constant E2BIG => ($! = 7);
    print   E2BIG, "\n";	# something like "Arg list too long"
    print 0+E2BIG, "\n";	# "7"

You can't produce a tied constant by giving a tied scalar as the
value.  References to tied variables, however, can be used as
constants without any problems.

Dereferencing constant references incorrectly (such as using an array
subscript on a constant hash reference, or vice versa) will be trapped at
compile time.

When declaring multiple constants, all constant values B<must be
scalars>.  If you accidentally try to use a list with more (or less)
than one value, every second value will be treated as a symbol name.

    use constant {
        EMPTY => (),                    # WRONG!
        MANY => ("foo", "bar", "baz"),  # WRONG!
    };

This will get interpreted as below, which is probably not what you
wanted.

    use constant {
        EMPTY => "MANY",  # oops.
        foo => "bar",     # oops!
        baz => undef,     # OOPS!
    };

This is a fundamental limitation of the way hashes are constructed in
Perl.  The error messages produced when this happens will often be
quite cryptic -- in the worst case there may be none at all, and
you'll only later find that something is broken.

In the rare case in which you need to discover at run time whether a
particular constant has been declared via this module, you may use
this function to examine the hash C<%constant::declared>. If the given
constant name does not include a package name, the current package is
used.

    sub declared ($) {
	use constant 1.01;		# don't omit this!
	my $name = shift;
	$name =~ s/^::/main::/;
	my $pkg = caller;
	my $full_name = $name =~ /::/ ? $name : "${pkg}::$name";
	$constant::declared{$full_name};
    }

=head1 TECHNICAL NOTE

In the current implementation, scalar constants are actually
inlinable subroutines. As of version 5.004 of Perl, the appropriate
scalar constant is inserted directly in place of some subroutine
calls, thereby saving the overhead of a subroutine call. See
L<perlsub/"Constant Functions"> for details about how and when this
happens.

=head1 BUGS

In the current version of Perl, list constants are not inlined
and some symbols may be redefined without generating a warning.

It is not possible to have a subroutine or keyword with the same
name as a constant in the same package. This is probably a Good Thing.

A constant with a name in the list C<STDIN STDOUT STDERR ARGV ARGVOUT
ENV INC SIG> is not allowed anywhere but in package C<main::>, for
technical reasons. 

Even though a reference may be declared as a constant, the reference may
point to data which may be changed, as this code shows.

    use constant CARRAY		=> [ 1,2,3,4 ];
    print CARRAY->[1];
    CARRAY->[1] = " be changed";
    print CARRAY->[1];

Unlike constants in some languages, these cannot be overridden
on the command line or via environment variables.

You can get into trouble if you use constants in a context which
automatically quotes barewords (as is true for any subroutine call).
For example, you can't say C<$hash{CONSTANT}> because C<CONSTANT> will
be interpreted as a string.  Use C<$hash{CONSTANT()}> or
C<$hash{+CONSTANT}> to prevent the bareword quoting mechanism from
kicking in.  Similarly, since the C<=E<gt>> operator quotes a bareword
immediately to its left, you have to say C<CONSTANT() =E<gt> 'value'>
(or simply use a comma in place of the big arrow) instead of
C<CONSTANT =E<gt> 'value'>.

=head1 AUTHOR

Tom Phoenix, E<lt>F<rootbeer@redcat.com>E<gt>, with help from
many other folks.

Multiple constant declarations at once added by Casey West,
E<lt>F<casey@geeknest.com>E<gt>.

Assorted documentation fixes by Ilmari Karonen,
E<lt>F<perl@itz.pp.sci.fi>E<gt>.

=head1 COPYRIGHT

Copyright (C) 1997, 1999 Tom Phoenix

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut
