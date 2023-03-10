package strict;

$strict::VERSION = "1.13";

my ( %bitmask, %explicit_bitmask );

BEGIN {
    # Verify that we're called correctly so that strictures will work.
    # Can't use Carp, since Carp uses us!
    # see also warnings.pm.
    die sprintf "Incorrect use of pragma '%s' at %s line %d.\n", __PACKAGE__, +(caller)[1,2]
        if __FILE__ !~ ( '(?x) \b     '.__PACKAGE__.'  \.pmc? \z' )
        && __FILE__ =~ ( '(?x) \b (?i:'.__PACKAGE__.') \.pmc? \z' );

    %bitmask = (
        refs => 0x00000002,
        subs => 0x00000200,
        vars => 0x00000400,
    );

    %explicit_bitmask = (
        refs => 0x00000020,
        subs => 0x00000040,
        vars => 0x00000080,
    );

    my $bits = 0;
    $bits |= $_ for values %bitmask;

    my $inline_all_bits = $bits;
    *all_bits = sub () { $inline_all_bits };

    $bits = 0;
    $bits |= $_ for values %explicit_bitmask;

    my $inline_all_explicit_bits = $bits;
    *all_explicit_bits = sub () { $inline_all_explicit_bits };
}

sub _compute_bits {
    my $bits = shift;
    my $sense = shift;
    my $apply_bits = $sense ? sub { $_[0] | $_[1] } : sub { $_[0] & ~$_[1] };
    my $adverb = $_[0] // "";
    my $proc_bits;
    if($adverb eq "softly") {
        shift;
        $proc_bits = sub { $_[0] & $_[2] ? $_[0] : $apply_bits->($_[0], $_[1]) };
    } elsif($adverb eq "forcing_softness") {
        shift;
        $proc_bits = sub { $apply_bits->($_[0] & ~$_[2], $_[1]) };
    } else {
        shift if $adverb eq "firmly";
        $proc_bits = sub { $apply_bits->($_[0] | $_[2], $_[1]) };
    }
    my @wrong;
    @_ or @_ = qw(refs subs vars);
    foreach my $s (@_) {
        if(exists $bitmask{$s}) {
            $bits = $proc_bits->($bits, $bitmask{$s}, $explicit_bitmask{$s});
        } else {
            push @wrong, $s;
        }
    }
    if (@wrong) {
        require Carp;
        Carp::croak("Unknown 'strict' tag(s) '@wrong'");
    }
    return $bits;
}

sub bits { _compute_bits(0, 1, "softly", @_) }

sub import {
    shift;
    $^H = _compute_bits($^H, 1, @_);
}

sub unimport {
    shift;
    $^H = _compute_bits($^H, 0, @_);
}

1;
__END__

=head1 NAME

strict - Perl pragma to restrict unsafe constructs

=head1 SYNOPSIS

    use strict;

    use strict "vars";
    use strict "refs";
    use strict "subs";

    use strict;
    no strict "vars";

=head1 DESCRIPTION

The C<strict> pragma disables certain Perl expressions that could behave
unexpectedly or are difficult to debug, turning them into errors. The
effect of this pragma is limited to the current file or scope block.
C<no strict> can be used to reenable the dubious types of expression.

Usually it is best to write programs of more than a couple of lines
with all strictures enabled at the top level, achieved by a simple
C<use strict>.  This is the safest mode to operate in.  Where a stricture
turns out to be counterproductive, one should then disable the specific
kind of stricture in as small a scope as possible.  For example, if one
needs to use a symbolic reference, one can write

    $referent = do { no strict "refs"; $$name };

so that symbolic references are permitted for the C<$$name> expression
but remain prohibited in surrounding code.

See L<perlmodlib/Pragmatic Modules>.

=head2 Subjects

The main arguments to the pragma are a list specifying which kinds
of expression the stricture is to apply to.  Currently, there are
three possible things to be strict about:  "subs", "vars", and "refs".
If no such arguments are given then the stricture applies to all three
categories.

=over 6

=item C<strict refs>

This generates a runtime error if you 
use symbolic references (see L<perlref>).

    use strict 'refs';
    $ref = \$foo;
    print $$ref;	# ok
    $ref = "foo";
    print $$ref;	# runtime error; normally ok
    $file = "STDOUT";
    print $file "Hi!";	# error; note: no comma after $file

There is one exception to this rule:

    $bar = \&{'foo'};
    &$bar;

is allowed so that C<goto &$AUTOLOAD> would not break under stricture.


=item C<strict vars>

This generates a compile-time error if you access a variable that was
neither explicitly declared (using any of C<my>, C<our>, C<state>, or C<use
vars>) nor fully qualified.  (Because this is to avoid variable suicide
problems and subtle dynamic scoping issues, a merely C<local> variable isn't
good enough.)  See L<perlfunc/my>, L<perlfunc/our>, L<perlfunc/state>,
L<perlfunc/local>, and L<vars>.

    use strict 'vars';
    $X::foo = 1;	 # ok, fully qualified
    my $foo = 10;	 # ok, my() var
    local $baz = 9;	 # blows up, $baz not declared before

    package Cinna;
    our $bar;			# Declares $bar in current package
    $bar = 'HgS';		# ok, global declared via pragma

The local() generated a compile-time error because you just touched a global
name without fully qualifying it.

Because of their special use by sort(), the variables $a and $b are
exempted from this check.

=item C<strict subs>

This disables the poetry optimization, generating a compile-time error if
you try to use a bareword identifier that's not a subroutine, unless it
is a simple identifier (no colons) and that it appears in curly braces,
on the left hand side of the C<< => >> symbol, or has the unary minus
operator applied to it.

    use strict 'subs';
    $SIG{PIPE} = Plumber;   # blows up
    $SIG{PIPE} = "Plumber"; # fine: quoted string is always ok
    $SIG{PIPE} = \&Plumber; # preferred form

=back

=head2 Adverb

The C<strict> pragma can optionally take an adverb before the (optional)
list of subjects, to say how the declaration should interact with other
declarations that affect strictures.  This is not useful when invoking
C<strict> directly to apply to one's own code.  It has some value when
setting up a lexical environment for someone else to use via C<eval>,
and also when implementing a lexical pragma that has multiple lexical
effects (a metapragma).  The adverb may be:

=over 6

=item B<firmly>

The requested strictures are unconditionally turned on (or off, with
C<no>), and qualify as firmly set.  This is the default if no adverb
is given.

=item B<softly>

Any of the requested strictures that were not already firmly set are
turned on (or off, with C<no>), and continue to not qualify as firmly set.
Any that were already firmly set have their status unchanged.

=item B<forcing_softness>

The requested strictures are unconditionally turned on (or off, with
C<no>), and no longer qualify as firmly set.

=back

C<no strict 'forcing_softness'> can be used to cancel the effects of all
prior C<strict> declarations, returning the lexical stricture state to
its default.  Specifically, this is needed for subsequent soft stricture
declarations to take effect.

=head2 Stricture implied by version declarations

A L<C<use VERSION>|perlfunc/use VERSION> declaration has some effect
on lexical stricture status.  If the specified Perl version is 5.37 or
higher, strictures are firmly enabled, as if by a simple C<use strict>.
If the version is 5.11 or higher but less than 5.37, then strictures are
softly enabled, as if by C<use strict 'softly'>.  If the version is less
than 5.11, then strictures are softly disabled, as if by C<no strict
'softly'>.

The version declarations have had these effects on strictures ever since
Perl 5.15.6, which introduced the concept of soft stricture enablement.
On Perls older than that the effects of version declarations was a bit
different: if the version was 5.11 or higher then strictures would be
firmly enabled, and if the version was less than 5.11 then strictures
would be unaffected.  This change in meaning of version declarations
for versions less than 5.15 was a historical mistake, which is now too
firmly entrenched to rectify.  Beware, therefore, when using a version
declaration with such a low version number.  Version declarations for
version 5.16 or higher have no such problem, having always had the same
effect on strictures that they do now.

The main use of the B<softly> adverb to the C<strict> pragma is to
imitate the effect of version declarations for versions less than 5.37.
The concept of soft stricture enablement is now considered a poor
design, and is not recommended for use in metapragmata that don't
specifically need to imitate historical version declarations.  It is
also not recommended to build a similar softness facility for a new
pragma that controls anything else.

=head1 HISTORY

C<strict 'subs'>, with Perl 5.6.1, erroneously permitted to use an unquoted
compound identifier (e.g. C<Foo::Bar>) as a hash key (before C<< => >> or
inside curlies), but without forcing it always to a literal string.

Starting with Perl 5.8.1 strict is strict about its restrictions:
if unknown restrictions are used, the strict pragma will abort with

    Unknown 'strict' tag(s) '...'

As of version 1.04 (Perl 5.10), strict verifies that it is used as
"strict" to avoid the dreaded Strict trap on case insensitive file
systems.

=cut
