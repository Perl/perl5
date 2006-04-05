package B::Lint;

our $VERSION = '1.06';

=head1 NAME

B::Lint - Perl lint

=head1 SYNOPSIS

perl -MO=Lint[,OPTIONS] foo.pl

=head1 DESCRIPTION

The B::Lint module is equivalent to an extended version of the B<-w>
option of B<perl>. It is named after the program F<lint> which carries
out a similar process for C programs.

=head1 OPTIONS AND LINT CHECKS

Option words are separated by commas (not whitespace) and follow the
usual conventions of compiler backend options. Following any options
(indicated by a leading B<->) come lint check arguments. Each such
argument (apart from the special B<all> and B<none> options) is a
word representing one possible lint check (turning on that check) or
is B<no-foo> (turning off that check). Before processing the check
arguments, a standard list of checks is turned on. Later options
override earlier ones. Available options are:

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

Both B<implicit-read> and B<implicit-write> warn about this:

    for (@a) { ... }

=item B<bare-subs>

This option warns whenever a bareword is implicitly quoted, but is also
the name of a subroutine in the current package. Typical mistakes that it will
trap are:

    use constant foo => 'bar';
    @a = ( foo => 1 );
    $b{foo} = 2;

Neither of these will do what a naive user would expect.

=item B<dollar-underscore>

This option warns whenever C<$_> is used either explicitly anywhere or
as the implicit argument of a B<print> statement.

=item B<private-names>

This option warns on each use of any variable, subroutine or
method name that lives in a non-current package but begins with
an underscore ("_"). Warnings aren't issued for the special case
of the single character name "_" by itself (e.g. C<$_> and C<@_>).

=item B<undefined-subs>

This option warns whenever an undefined subroutine is invoked.
This option will only catch explicitly invoked subroutines such
as C<foo()> and not indirect invocations such as C<&$subref()>
or C<$obj-E<gt>meth()>. Note that some programs or modules delay
definition of subs until runtime by means of the AUTOLOAD
mechanism.

=item B<regexp-variables>

This option warns whenever one of the regexp variables C<$`>, C<$&> or C<$'>
is used. Any occurrence of any of these variables in your
program can slow your whole program down. See L<perlre> for
details.

=item B<all>

Turn all warnings on.

=item B<none>

Turn all warnings off.

=back

=head1 NON LINT-CHECK OPTIONS

=over 8

=item B<-u Package>

Normally, Lint only checks the main code of the program together
with all subs defined in package main. The B<-u> option lets you
include other package names whose subs are then checked by Lint.

=back

=head1 EXTENDING LINT

Lint can be extended by registering plugins.

The C<< B::Lint->register_plugin( MyPlugin => \@new_checks ) >> method
adds the class C<MyPlugin> to the list of plugins. It also adds the
list of C<@new_checks> to the list of valid checks.

You must create a C<match( \%checks )> method in your plugin class or one
of its parents. It will be called on every op as a regular method call
with a hash ref of checks as its parameter.

You may not alter the %checks hash reference.

The class methods C<< B::Lint->file >> and C<< B::Lint->line >> contain
the current filename and line number.

  package Sample;
  use B::Lint;
  B::Lint->register_plugin( Sample => [ 'good_taste' ] );
  
  sub match {
      my ( $op, $checks_href ) = shift;
      if ( $checks_href->{good_taste} ) {
          ...
      }
  }

=head1 BUGS

This is only a very preliminary version.

This module doesn't work correctly on thread-enabled perls.

=head1 AUTHOR

Malcolm Beattie, mbeattie@sable.ox.ac.uk.

=cut

use strict;
use B qw(walkoptree_slow main_root walksymtable svref_2object parents
         class
         OPpOUR_INTRO
         OPf_WANT_VOID OPf_WANT_LIST OPf_WANT OPf_STACKED G_ARRAY SVf_POK
        );

my $file = "unknown";		# shadows current filename
my $line = 0;			# shadows current line number
my $curstash = "main";		# shadows current stash

sub file { $file }
sub line { $line }

# Lint checks
my %check;
my %implies_ok_context;
BEGIN {
    map($implies_ok_context{$_}++,
	qw(scalar av2arylen aelem aslice helem hslice
	   keys values hslice defined undef delete));
}

# Lint checks turned on by default
my @default_checks = qw(context);

my %valid_check;
my %plugin_valid_check;
# All valid checks
BEGIN {
    map($valid_check{$_}++,
	qw(context implicit_read implicit_write dollar_underscore
	   private_names bare_subs undefined_subs regexp_variables));
}

# Debugging options
my ($debug_op);

my %done_cv;		# used to mark which subs have already been linted
my @extra_packages;	# Lint checks mainline code and all subs which are
			# in main:: or in one of these packages.

sub warning {
    my $format = (@_ < 2) ? "%s" : shift;
    warn sprintf("$format at %s line %d\n", @_, $file, $line);
}

# This gimme can't cope with context that's only determined
# at runtime via dowantarray().
sub gimme {
    my $op = shift;
    my $flags = $op->flags;
    if ($flags & OPf_WANT) {
	return(($flags & OPf_WANT) == OPf_WANT_LIST ? 1 : 0);
    }
    return undef;
}

my @plugins;

sub B::OP::lint {
    my $op = shift;
    my $m;
    $m = $_->can('match'), $op->$m( \ %check ) for @plugins;
    return;
}

*$_ = *B::OP::lint
  for \ ( *B::PADOP::lint,
          *B::LOGOP::lint,
          *B::BINOP::lint,
          *B::LISTOP::lint );

sub B::COP::lint {
    my $op = shift;
    if ($op->name eq "nextstate") {
	$file = $op->file;
	$line = $op->line;
	$curstash = $op->stash->NAME;
    }

    my $m;
    $m = $_->can('match'), $op->$m( \ %check ) for @plugins;
    return;
}

sub B::UNOP::lint {
    my $op = shift;
    my $opname = $op->name;
    if ($check{context} && ($opname eq "rv2av" || $opname eq "rv2hv")) {
	my $parent = parents->[0];
	my $pname = $parent->name;
	return if gimme($op) || $implies_ok_context{$pname};
	# Three special cases to deal with: "foreach (@foo)", "delete $a{$b}", and "exists $a{$b}"
	# null out the parent so we have to check for a parent of pp_null and
	# a grandparent of pp_enteriter, pp_delete, pp_exists
	if ($pname eq "null") {
	    my $gpname = parents->[1]->name;
	    return if $gpname eq "enteriter"
                   or $gpname eq "delete"
                   or $gpname eq "exists";
	}
	
	# our( @bar );
	return if $op->private & OPpOUR_INTRO
                  and ( $op->flags & OPf_WANT ) == OPf_WANT_VOID;
	
	warning("Implicit scalar context for %s in %s",
		$opname eq "rv2av" ? "array" : "hash", $parent->desc);
    }
    if ($check{private_names} && $opname eq "method") {
	my $methop = $op->first;
	if ($methop->name eq "const") {
	    my $method = $methop->sv->PV;
	    if ($method =~ /^_/ && !defined(&{"$curstash\::$method"})) {
		warning("Illegal reference to private method name $method");
	    }
	}
    }

    my $m;
    $m = $_->can('match'), $op->$m( \ %check ) for @plugins;
    return;
}

sub B::PMOP::lint {
    my $op = shift;
    if ($check{implicit_read}) {
	if ($op->name eq "match"
		and not ( $op->flags & OPf_STACKED
		    or join( " ",
			map $_->name,
			@{B::parents()} )
		=~ /^(?:leave )?(?:null )*grep/ ) ) {
	    warning('Implicit match on $_');
	}
    }
    if ($check{implicit_write}) {
	if ($op->name eq "subst" && !($op->flags & OPf_STACKED)) {
	    warning('Implicit substitution on $_');
	}
    }

    my $m;
    $m = $_->can('match'), $op->$m( \ %check ) for @plugins;
    return;
}

sub B::LOOP::lint {
    my $op = shift;
    if ($check{implicit_read} || $check{implicit_write}) {
	if ($op->name eq "enteriter") {
	    my $last = $op->last;
	    my $body = $op->redoop;
	    if ( $last->name eq "gv"
		 and $last->gv->NAME eq "_"
	         and $body->name =~ /\A(?:next|db|set)state\z/ ) {
		warning('Implicit use of $_ in foreach');
	    }
	}
    }
    
    my $m;
    $m = $_->can('match'), $op->$m( \ %check ) for @plugins;
    return;
}

sub _inside_foreach_statement {
    for my $op ( @{ parents() || [] } ) {
	$op->name eq 'leaveloop' or next;
	my $first = $op->first;
	$first->name eq 'enteriter' or next;
	$first->redoop->name !~ /\A(?:next|db|set)state\z/ or next;
	return 1;
    }
    return 0;
}

sub B::SVOP::lint {
    my $op = shift;
    if ( $check{bare_subs} && $op->name eq 'const'
         && $op->private & 64 )		# OPpCONST_BARE = 64 in op.h
    {
	my $sv = $op->sv;
	if( $sv->FLAGS & SVf_POK && exists &{$curstash.'::'.$sv->PV} ) {
	    warning "Bare sub name '" . $sv->PV . "' interpreted as string";
	}
    }
    if ($check{dollar_underscore}
	and $op->name eq "gvsv"
	and $op->gv->NAME eq "_"
	and not ( _inside_foreach_statement()
		  or do { my $ctx = join( ' ',
					  map $_->name,
					  @{ parents() || [] } );
			  $ctx =~ /(grep|map)start \1while/ } ) )
    {
	warning('Use of $_');
    }
    if ($check{private_names}) {
	my $opname = $op->name;
	if ($opname eq "gv" || $opname eq "gvsv") {
	    my $gv = $op->gv;
	    if ($gv->NAME =~ /^_./ && $gv->STASH->NAME ne $curstash) {
		warning('Illegal reference to private name %s', $gv->NAME);
	    }
	} elsif ($opname eq "method_named") {
	    my $method = $op->gv->PV;
	    if ($method =~ /^_./) {
		warning("Illegal reference to private method name $method");
	    }
	}
    }
    if ($check{undefined_subs}) {
	if ($op->name eq "gv"
	    && $op->next->name eq "entersub")
	{
	    my $gv = $op->gv;
	    my $subname = $gv->STASH->NAME . "::" . $gv->NAME;
	    no strict 'refs';
	    if (!defined(&$subname)) {
		$subname =~ s/^main:://;
		warning('Undefined subroutine %s called', $subname);
	    }
	}
    }
    if ($check{regexp_variables} && $op->name eq "gvsv") {
	my $name = $op->gv->NAME;
	if ($name =~ /^[&'`]$/) {
	    warning('Use of regexp variable $%s', $name);
	}
    }
    
    my $m;
    $m = $_->can('match'), $op->$m( \ %check ) for @plugins;
    return;
}

sub B::GV::lintcv {
    my $gv = shift;
    my $cv = $gv->CV;
    #warn sprintf("lintcv: %s::%s (done=%d)\n",
    #		 $gv->STASH->NAME, $gv->NAME, $done_cv{$$cv});#debug
    return if !$$cv || $done_cv{$$cv}++;
    my $root = $cv->ROOT;
    #warn "    root = $root (0x$$root)\n";#debug
    walkoptree_slow($root, "lint") if $$root;
}

sub do_lint {
    my %search_pack;
    walkoptree_slow(main_root, "lint") if ${main_root()};
    
    # Now do subs in main
    no strict qw(vars refs);
    local(*glob);
    for my $sym (keys %main::) {
	next if $sym =~ /::$/;
	*glob = $main::{$sym};
	
        # When is EGV a special value?
        my $gv = svref_2object(\*glob)->EGV;
        next if class( $gv ) eq 'SPECIAL';
        $gv->lintcv;
    }

    # Now do subs in non-main packages given by -u options
    map { $search_pack{$_} = 1 } @extra_packages;
    walksymtable(\%{"main::"}, "lintcv", sub {
	my $package = shift;
	$package =~ s/::$//;
	#warn "Considering $package\n";#debug
	return exists $search_pack{$package};
    });
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
	} elsif ($opt eq "u") {
	    $arg ||= shift @options;
	    push(@extra_packages, $arg);
	}
    }
    foreach $opt (@default_checks, @options) {
	$opt =~ tr/-/_/;
	if ($opt eq "all") {
            %check = ( %valid_check, %plugin_valid_check );
	}
	elsif ($opt eq "none") {
	    %check = ();
	}
	else {
	    if ($opt =~ s/^no_//) {
		$check{$opt} = 0;
	    }
	    else {
		$check{$opt} = 1;
	    }
	    warn "No such check: $opt\n" unless defined $valid_check{$opt}
                                             or defined $plugin_valid_check{$opt};
	}
    }
    # Remaining arguments are things to check

    return \&do_lint;
}

sub register_plugin {
    my ( undef, $plugin, $new_checks ) = @_;

    # Register the plugin
    for my $check ( @$new_checks ) {
        defined $check
          or warn "Undefined value in checks.";
        not $valid_check{ $check }
          or warn "$check is already registered as a B::Lint feature.";
        not $plugin_valid_check{ $check }
          or warn "$check is already registered as a $plugin_valid_check{$check} feature.";

        $plugin_valid_check{$check} = $plugin;
    }

    push @plugins, $plugin;

    return;
}

1;
