package re;

our $VERSION = 0.06_02;

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

    use re 'debug';		   # output debugging info during
    /^(.*)$/s;			   #     compile and run time


    use re 'debugcolor';	   # same as 'debug', but with colored output
    ...

    use re qw(Debug All);          # Finer tuned debugging options.
    use re qw(Debug More);         
    no re qw(Debug ALL);           # Turn of all re debugging in this scope

(We use $^X in these examples because it's tainted by default.)

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
disallowed with tainted regular expressions.  See L<perlre/(?{ code })>.

For the purpose of this pragma, interpolation of precompiled regular
expressions (i.e., the result of C<qr//>) is I<not> considered variable
interpolation.  Thus:

    /foo${pat}bar/

I<is> allowed if $pat is a precompiled regular expression, even
if $pat contains C<(?{ ... })> assertions.

When C<use re 'debug'> is in effect, perl emits debugging messages when
compiling and using regular expressions.  The output is the same as that
obtained by running a C<-DDEBUGGING>-enabled perl interpreter with the
B<-Dr> switch. It may be quite voluminous depending on the complexity
of the match.  Using C<debugcolor> instead of C<debug> enables a
form of output that can be used to get a colorful display on terminals
that understand termcap color sequences.  Set C<$ENV{PERL_RE_TC}> to a
comma-separated list of C<termcap> properties to use for highlighting
strings on/off, pre-point part on/off.
See L<perldebug/"Debugging regular expressions"> for additional info.

Similarly C<use re 'Debug'> produces debugging output, the difference
being that it allows the fine tuning of what debugging output will be
emitted. Options are divided into three groups, those related to
compilation, those related to execution and those related to special
purposes. The options are as follows:

=over 4

=item Compile related options

=over 4

=item COMPILE

Turns on all compile related debug options.

=item PARSE

Turns on debug output related to the process of parsing the pattern.

=item OPTIMISE

Enables output related to the optimisation phase of compilation.

=item TRIEC

Detailed info about trie compilation.

=item DUMP

Dump the final program out after it is compiled and optimised.


=back

=item Execute related options

=over 4

=item EXECUTE

Turns on all execute related debug options.

=item MATCH

Turns on debugging of the main matching loop.

=item TRIEE

Extra debugging of how tries execute.

=item INTUIT

Enable debugging of start point optimisations.

=back

=item Extra debugging options

=over 4

=item EXTRA

Turns on all "extra" debugging options.

=item TRIEM

Enable enhanced TRIE debugging. Enhances both TRIEE
and TRIEC.

=item STATE

Enable debugging of states in the engine. 

=item STACK

Enable debugging of the recursion stack in the engine. Enabling
or disabling this option automatically does the same for debugging
states as well. This output from this can be quite large.

=item OPTIMISEM

Enable enhanced optimisation debugging and start point optimisations.
Probably not useful except when debugging the regex engine itself.

=item OFFSETS

Dump offset information. This can be used to see how regops correlate
to the pattern. Output format is

   NODENUM:POSITION[LENGTH]

Where 1 is the position of the first char in the string. Note that position
can be 0, or larger than the actual length of the pattern, likewise length
can be zero.

=item OFFSETSDBG

Enable debugging of offsets information. This emits copious
amounts of trace information and doesn't mesh well with other
debug options.

Almost definitely only useful to people hacking
on the offsets part of the debug engine.

=back

=item Other useful flags

These are useful shortcuts to save on the typing.

=over 4

=item ALL

Enable all compile and execute options at once.

=item All

Enable DUMP and all execute options. Equivalent to:

  use re 'debug';

=item MORE

=item More

Enable TRIEM and all execute compile and execute options.

=back

=back

As of 5.9.5 the directive C<use re 'debug'> and its equivalents are
lexically scoped, as the other directives are.  However they have both 
compile-time and run-time effects.

See L<perlmodlib/Pragmatic Modules>.

=cut

# N.B. File::Basename contains a literal for 'taint' as a fallback.  If
# taint is changed here, File::Basename must be updated as well.
my %bitmask = (
taint		=> 0x00100000, # HINT_RE_TAINT
eval		=> 0x00200000, # HINT_RE_EVAL
);

sub setcolor {
 eval {				# Ignore errors
  require Term::Cap;

  my $terminal = Tgetent Term::Cap ({OSPEED => 9600}); # Avoid warning.
  my $props = $ENV{PERL_RE_TC} || 'md,me,so,se,us,ue';
  my @props = split /,/, $props;
  my $colors = join "\t", map {$terminal->Tputs($_,1)} @props;

  $colors =~ s/\0//g;
  $ENV{PERL_RE_COLORS} = $colors;
 };
 if ($@) {
    $ENV{PERL_RE_COLORS}||=qq'\t\t> <\t> <\t\t'
 }

}

my %flags = (
    COMPILE         => 0x0000FF,
    PARSE           => 0x000001,
    OPTIMISE        => 0x000002,
    TRIEC           => 0x000004,
    DUMP            => 0x000008,

    EXECUTE         => 0x00FF00,
    INTUIT          => 0x000100,
    MATCH           => 0x000200,
    TRIEE           => 0x000400,

    EXTRA           => 0xFF0000,
    TRIEM           => 0x010000,
    OFFSETS         => 0x020000,
    OFFSETSDBG      => 0x040000,
    STATE           => 0x080000,
    OPTIMISEM       => 0x100000,
    STACK           => 0x280000,
);
$flags{ALL} = -1;
$flags{All} = $flags{all} = $flags{DUMP} | $flags{EXECUTE};
$flags{Extra} = $flags{EXECUTE} | $flags{COMPILE};
$flags{More} = $flags{MORE} = $flags{All} | $flags{TRIEC} | $flags{TRIEM} | $flags{STATE};
$flags{State} = $flags{DUMP} | $flags{EXECUTE} | $flags{STATE};
$flags{TRIE} = $flags{DUMP} | $flags{EXECUTE} | $flags{TRIEC};

my $installed;
my $installed_error;

sub _load_unload {
    my ($on)= @_;
    if ($on) {
        if ( ! defined($installed) ) {
            require XSLoader;
            $installed = eval { XSLoader::load('re') } || 0;
            $installed_error = $@;
        }
        if ( ! $installed ) {
            die "'re' not installed!? ($installed_error)";
	} else {
	    # We call install() every time, as if we didn't, we wouldn't
	    # "see" any changes to the color environment var since
	    # the last time it was called.

	    # install() returns an integer, which if casted properly
	    # in C resolves to a structure containing the regex
	    # hooks. Setting it to a random integer will guarantee
	    # segfaults.
	    $^H{regcomp} = install();
        }
    } else {
        delete $^H{regcomp};
    }
}

sub bits {
    my $on = shift;
    my $bits = 0;
    unless (@_) {
	return;
    }
    foreach my $idx (0..$#_){
        my $s=$_[$idx];
        if ($s eq 'Debug' or $s eq 'Debugcolor') {
            setcolor() if $s =~/color/i;
            ${^RE_DEBUG_FLAGS} = 0 unless defined ${^RE_DEBUG_FLAGS};
            for my $idx ($idx+1..$#_) {
                if ($flags{$_[$idx]}) {
                    if ($on) {
                        ${^RE_DEBUG_FLAGS} |= $flags{$_[$idx]};
                    } else {
                        ${^RE_DEBUG_FLAGS} &= ~ $flags{$_[$idx]};
                    }
                } else {
                    require Carp;
                    Carp::carp("Unknown \"re\" Debug flag '$_[$idx]', possible flags: ",
                               join(", ",sort keys %flags ) );
                }
            }
            _load_unload($on ? 1 : ${^RE_DEBUG_FLAGS});
            last;
        } elsif ($s eq 'debug' or $s eq 'debugcolor') {
	    setcolor() if $s =~/color/i;
	    _load_unload($on);
        } elsif (exists $bitmask{$s}) {
	    $bits |= $bitmask{$s};
	} else {
	    require Carp;
	    Carp::carp("Unknown \"re\" subpragma '$s' (known ones are: ",
                       join(', ', map {qq('$_')} 'debug', 'debugcolor', sort keys %bitmask),
                       ")");
	}
    }
    $bits;
}

sub import {
    shift;
    $^H |= bits(1, @_);
}

sub unimport {
    shift;
    $^H &= ~ bits(0, @_);
}

1;
