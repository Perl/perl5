package re;

$VERSION = 0.02;

=head1 NAME

re - Perl pragma to alter regular expression behaviour

=head1 SYNOPSIS

    use re 'taint';
    ($x) = ($^X =~ /^(.*)$/s);     # $x is tainted here

    $pat = '(?{ $foo = 1 })';
    use re 'eval';
    /foo${pat}bar/;		   # won't fail (when not under -T switch)

    {
	no re 'taint';		   # the default
	($x) = ($^X =~ /^(.*)$/s); # $x is not tainted here

	no re 'eval';		   # the default
	/foo${pat}bar/;		   # disallowed (with or without -T switch)
    }

    use re 'debug';
    /^(.*)$/s;			   # output debugging info 
				   # during compile and run time

=head1 DESCRIPTION

When C<use re 'taint'> is in effect, and a tainted string is the target
of a regex, the regex memories (or values returned by the m// operator
in list context) are tainted.  This feature is useful when regex operations
on tainted data aren't meant to extract safe substrings, but to perform
other transformations.

When C<use re 'eval'> is in effect, a regex is allowed to contain
C<(?{ ... })> zero-width assertions even if regular expression contains
variable interpolation.  That is normally disallowed, since it is a 
potential security risk.  Note that this pragma is ignored when the regular
expression is obtained from tainted data, i.e.  evaluation is always
disallowed with tainted regular expresssions.  See L<perlre/(?{ code })>.

For the purpose of this pragma, interpolation of preexisting regular 
expressions is I<not> considered a variable interpolation, thus

    /foo${pat}bar/

I<is> allowed if $pat is a preexisting regular expressions, even 
if $pat contains C<(?{ ... })> assertions.

When C<use re 'debug'> is in effect, perl emits debugging messages when 
compiling and using regular expressions.  The output is the same as that
obtained by running a C<-DDEBUGGING>-enabled perl interpreter with the
B<-Dr> switch. It may be quite voluminous depending on the complexity
of the match.
See L<perldebug/"Debugging regular expressions"> for additional info.

I<The directive C<use re 'debug'> is not lexically scoped.>  It has 
both compile-time and run-time effects.

See L<perlmodlib/Pragmatic Modules>.

=cut

my %bitmask = (
taint	=> 0x00100000,
eval	=> 0x00200000,
);

sub bits {
    my $on = shift;
    my $bits = 0;
    unless(@_) {
	require Carp;
	Carp::carp("Useless use of \"re\" pragma");
    }
    foreach my $s (@_){
      if ($s eq 'debug') {
	  eval <<'EOE';
	    use DynaLoader;
	    @ISA = ('DynaLoader');
	    bootstrap re;
EOE
	  install() if $on;
	  uninstall() unless $on;
	  next;
      }
      $bits |= $bitmask{$s} || 0;
    }
    $bits;
}

sub import {
    shift;
    $^H |= bits(1,@_);
}

sub unimport {
    shift;
    $^H &= ~ bits(0,@_);
}

1;
