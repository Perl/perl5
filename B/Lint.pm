package B::Lint;

=head1 NAME

B::Lint - Perl lint

=head1 SYNOPSIS

perl -MO=Lint[,OPTIONS] foo.pl

=head1 DESCRIPTION

The B::Lint module is equivalent to an extended version of the B<-w>
option of B<perl>. It is named after the program B<lint> which carries
out a similar process for C programs.

=head1 OPTIONS AND LINT CHECKS

Option words are separated by commas (not whitespace) and follow the
usual conventions of compiler backend options. Following any options
(indicated by a leading B<->) come lint check arguments. Each is a
word representing one possible lint check (turning on that check) or
is B<no-foo> meaning to turn off check B<foo>. By default, a standard
list of checks is turned on. Available checks are:

=over 8

=item B<context>

Produces a warning whenever an array is used in an implicit scalar
context. For example, both of the lines

    $foo = length(@bar);
    $foo = @bar;
will elicit a warning. Using an explicit B<scalar()> silences the
warning. For example,

    $foo = scalar(@bar);

=item B<implicit-read> and B<implicit-write>

These options produce a warning whenever an operation implicitly
reads or (respectively) writes to one of Perl's special variables.
For example, B<implicit-read> will warn about these:

    /foo/;

and B<implicit-write> will warn about these:

    s/foo/bar/;

=back

=head1 BUGS

This is only a very preliminary version.

=head1 AUTHOR

Malcolm Beattie, mbeattie@sable.ox.ac.uk.

=cut

use strict;
use B qw(walkoptree_slow main_root parents);

# Constants (should probably be elsewhere)
sub G_ARRAY () { 1 }
sub OPf_LIST () { 1 }
sub OPf_KNOW () { 2 }
sub OPf_STACKED () { 64 }

my $file = "unknown";		# shadows current filename
my $line = 0;			# shadows current line number

# Lint checks
my %check;
my %implies_ok_context;
BEGIN {
    map($implies_ok_context{$_}++,
	qw(pp_scalar pp_av2arylen pp_aelem pp_aslice pp_helem pp_hslice
	   pp_keys pp_values pp_hslice pp_defined pp_undef pp_delete));
}

# Lint checks turned on by default
my @default_checks = qw(context);

# Debugging options
my ($debug_op);

sub warning {
    my $format = (@_ < 2) ? "%s" : shift;
    warn sprintf("$format at %s line %d\n", @_, $file, $line);
}

# This gimme can't cope with context that's only determined
# at runtime via dowantarray().
sub gimme {
    my $op = shift;
    my $flags = $op->flags;
    if ($flags & OPf_KNOW) {
	return(($flags & OPf_LIST) ? 1 : 0);
    }
    return undef;
}

sub B::OP::lint {}

sub B::COP::lint {
    my $op = shift;
    if ($op->ppaddr eq "pp_nextstate") {
	$file = $op->filegv->SV->PV;
	$line = $op->line;
    }
}

sub B::UNOP::lint {
    my $op = shift;
    my $ppaddr = $op->ppaddr;
    if ($check{context} && ($ppaddr eq "pp_rv2av" || $ppaddr eq "pp_rv2hv")) {
	my $parent = parents->[0];
	my $pname = $parent->ppaddr;
	return if gimme($op) || $implies_ok_context{$pname};
	# Two special cases to deal with: "foreach (@foo)" and "delete $a{$b}"
	# null out the parent so we have to check for a parent of pp_null and
	# a grandparent of pp_enteriter or pp_delete
	if ($pname eq "pp_null") {
	    my $gpname = parents->[1]->ppaddr;
	    return if $gpname eq "pp_enteriter" || $gpname eq "pp_delete";
	}
	warning("Implicit scalar context for %s in %s",
		$ppaddr eq "pp_rv2av" ? "array" : "hash", $parent->desc);
    }
}

sub B::PMOP::lint {
    my $op = shift;
    if ($check{implicit_read}) {
	my $ppaddr = $op->ppaddr;
	if ($ppaddr eq "pp_match" && !($op->flags & OPf_STACKED)) {
	    warning('Implicit match on $_');
	}
    }
    elsif ($check{implicit_write}) {
	my $ppaddr = $op->ppaddr;
	if ($ppaddr eq "pp_subst" && !($op->flags & OPf_STACKED)) {
	    warning('Implicit substitution on $_');
	}
    }
}

sub compile {
    my @options = @_;
    my ($option, $opt, $arg);
    # Turn on default lint checks
    for $opt (@default_checks) {
	$check{$opt} = 1;
    }
  OPTION:
    while ($option = shift @options) {
	if ($option =~ /^-(.)(.*)/) {
	    $opt = $1;
	    $arg = $2;
	} else {
	    unshift @options, $option;
	    last OPTION;
	}
	if ($opt eq "-" && $arg eq "-") {
	    shift @options;
	    last OPTION;
	} elsif ($opt eq "D") {
            $arg ||= shift @options;
	    foreach $arg (split(//, $arg)) {
		if ($arg eq "o") {
		    B->debug(1);
		} elsif ($arg eq "O") {
		    $debug_op = 1;
		}
	    }
	}
    }
    foreach $opt (@default_checks, @options) {
	$opt =~ tr/-/_/;
	if ($opt =~ s/^no-//) {
	    $check{$opt} = 0;
	} else {
	    $check{$opt} = 1;
	}
    }
    # Remaining arguments are things to check
    
    return sub { walkoptree_slow(main_root, "lint") };
}

1;
