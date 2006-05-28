package re;

our $VERSION = 0.06_01;

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

    use re 'debug';		   # NOT lexically scoped (as others are)
    /^(.*)$/s;			   # output debugging info during
    				   #     compile and run time

    use re 'debugcolor';	   # same as 'debug', but with colored output
    ...

    use re qw(Debug All);          # Finer tuned debugging options.
    use re qw(Debug More);         # Similarly not lexically scoped.
    no re qw(Debug ALL);           # Turn of all re dugging and unload the module.

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
emitted. Following the 'Debug' keyword one of several options may be
provided: COMPILE, EXECUTE, TRIE_COMPILE, TRIE_EXECUTE, TRIE_MORE,
OPTIMISE, OFFSETS and ALL. Additionally the special keywords 'All' and
'More' may be provided. 'All' represents everything but OPTIMISE and
OFFSETS and TRIE_MORE, and 'More' is similar but include TRIE_MORE.
Saying C<< no re Debug => 'EXECUTE' >> will disable executing debug
statements and saying C<< use re Debug => 'EXECUTE' >> will turn it on. Note
that these flags can be set directly via ${^RE_DEBUG_FLAGS} by using the
following flag values:


    RE_DEBUG_COMPILE       0x01
    RE_DEBUG_EXECUTE       0x02
    RE_DEBUG_TRIE_COMPILE  0x04
    RE_DEBUG_TRIE_EXECUTE  0x08
    RE_DEBUG_TRIE_MORE     0x10
    RE_DEBUG_OPTIMISE      0x20
    RE_DEBUG_OFFSETS       0x40
    RE_DEBUG_PARSE         0x80

The directive C<use re 'debug'> and its equivalents are I<not> lexically
scoped, as the other directives are.  They have both compile-time and run-time
effects.

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
}

my %flags = (
    COMPILE      => 1,
    EXECUTE      => 2,
    TRIE_COMPILE => 4,
    TRIE_EXECUTE => 8,
    TRIE_MORE    => 16,
    OPTIMISE     => 32,
    OPTIMIZE     => 32, # alias
    OFFSETS      => 64,
    PARSE        => 128,
    ALL          => 255,
    All          => 15,
    More         => 31,
);

my $installed = 0;

sub _load_unload {
    my $on = shift;
    require XSLoader;
    XSLoader::load('re');
    install($on);
}

sub bits {
    my $on = shift;
    my $bits = 0;
    unless (@_) {
	require Carp;
	Carp::carp("Useless use of \"re\" pragma");
    }
    foreach my $idx (0..$#_){
        my $s=$_[$idx];
        if ($s eq 'Debug' or $s eq 'Debugcolor') {
            setcolor() if $s eq 'Debugcolor';
            ${^RE_DEBUG_FLAGS} = 0 unless defined ${^RE_DEBUG_FLAGS};
            for my $idx ($idx+1..$#_) {
                if ($flags{$_[$idx]}) {
                    if ($on) {
                        ${^RE_DEBUG_FLAGS} |= $flags{$_[$idx]};
                        ${^RE_DEBUG_FLAGS} |= 1
                                if $flags{$_[$idx]}>2;
                    } else {
                        ${^RE_DEBUG_FLAGS} &= ~ $flags{$_[$idx]};
                    }
                } else {
                    require Carp;
                    Carp::carp("Unknown \"re\" Debug flag '$_[$idx]', possible flags: ",
                               join(", ",sort { $flags{$a} <=> $flags{$b} } keys %flags ) );
                }
            }
            _load_unload($on ? 1 : ${^RE_DEBUG_FLAGS});
            last;
        } elsif ($s eq 'debug' or $s eq 'debugcolor') {
	    setcolor() if $s eq 'debugcolor';
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
