package Exporter;

=head1 Comments

If the first entry in an import list begins with !, : or / then the
list is treated as a series of specifications which either add to or
delete from the list of names to import. They are processed left to
right. Specifications are in the form:

    [!]name         This name only
    [!]:DEFAULT     All names in @EXPORT
    [!]:tag         All names in $EXPORT_TAGS{tag} anonymous list
    [!]/pattern/    All names in @EXPORT and @EXPORT_OK which match

A leading ! indicates that matching names should be deleted from the
list of names to import.  If the first specification is a deletion it
is treated as though preceded by :DEFAULT. If you just want to import
extra names in addition to the default set you will still need to
include :DEFAULT explicitly.

e.g., Module.pm defines:

    @EXPORT      = qw(A1 A2 A3 A4 A5);
    @EXPORT_OK   = qw(B1 B2 B3 B4 B5);
    %EXPORT_TAGS = (T1 => [qw(A1 A2 B1 B2)], T2 => [qw(A1 A2 B3 B4)]);

    Note that you cannot use tags in @EXPORT or @EXPORT_OK.
    Names in EXPORT_TAGS must also appear in @EXPORT or @EXPORT_OK.

Application says:

    use Module qw(:DEFAULT :T2 !B3 A3);
    use Socket qw(!/^[AP]F_/ !SOMAXCONN !SOL_SOCKET);
    use POSIX  qw(/^S_/ acos asin atan /^E/ !/^EXIT/);

You can set C<$Exporter::Verbose=1;> to see how the specifications are
being processed and what is actually being imported into modules.

=head2 Module Version Checking

The Exporter module will convert an attempt to import a number from a
module into a call to $module_name->require_version($value). This can
be used to validate that the version of the module being used is
greater than or equal to the required version.

The Exporter module supplies a default require_version method which
checks the value of $VERSION in the exporting module.

=cut

require 5.001;

$ExportLevel = 0;
$Verbose = 0;

require Carp;

sub export {

    # First make import warnings look like they're coming from the "use".
    local $SIG{__WARN__} = sub {
	my $text = shift;
	$text =~ s/ at \S*Exporter.pm line \d+.\n//;
	local $Carp::CarpLevel = 1;	# ignore package calling us too.
	Carp::carp($text);
    };

    my $pkg = shift;
    my $callpkg = shift;
    my @imports = @_;
    my($type, $sym);
    *exports = \@{"${pkg}::EXPORT"};
    if (@imports) {
	my $oops;
	*exports = \%{"${pkg}::EXPORT"};
	if (!%exports) {
	    grep(s/^&//, @exports);
	    @exports{@exports} = (1) x  @exports;
	    foreach $extra (@{"${pkg}::EXPORT_OK"}) {
		$exports{$extra} = 1;
	    }
	}

	if ($imports[0] =~ m#^[/!:]#){
	    my(@allexports) = keys %exports;
	    my $tagsref = \%{"${pkg}::EXPORT_TAGS"};
	    my $tagdata;
	    my %imports;
	    # negated first item implies starting with default set:
	    unshift(@imports, ':DEFAULT') if $imports[0] =~ m/^!/;
	    foreach (@imports){
		my(@names);
		my($mode,$spec) = m/^(!)?(.*)/;
		$mode = '+' unless defined $mode;

		@names = ($spec); # default, maybe overridden below

		if ($spec =~ m:^/(.*)/$:){
		    my $patn = $1;
		    @names = grep(/$patn/, @allexports); # XXX anchor by default?
		}
		elsif ($spec =~ m#^:(.*)# and $tagsref){
		    if ($1 eq 'DEFAULT'){
			@names = @exports;
		    }
		    elsif ($tagsref and $tagdata = $tagsref->{$1}) {
			@names = @$tagdata;
		    }
		}

		warn "Import Mode $mode, Spec $spec, Names @names\n" if $Verbose;
		if ($mode eq '!') {
		   map {delete $imports{$_}} @names; # delete @imports{@names} would be handy :-)
		}
		else {
		   @imports{@names} = (1) x @names;
		}
	    }
	    @imports = keys %imports;
	}

	foreach $sym (@imports) {
	    if (!$exports{$sym}) {
		if ($sym =~ m/^\d/) {
		    $pkg->require_version($sym);
		    # If the version number was the only thing specified
		    # then we should act as if nothing was specified:
		    if (@imports == 1) {
			@imports = @exports;
			last;
		    }
		} elsif ($sym !~ s/^&// || !$exports{$sym}) {
		    warn qq["$sym" is not exported by the $pkg module ],
			    "at $callfile line $callline\n";
		    $oops++;
		    next;
		}
	    }
	}
	Carp::croak("Can't continue with import errors.\n") if $oops;
    }
    else {
	@imports = @exports;
    }
    warn "Importing from $pkg into $callpkg: ",
		join(", ",@imports),"\n" if ($Verbose && @imports);
    foreach $sym (@imports) {
	$type = '&';
	$type = $1 if $sym =~ s/^(\W)//;
	*{"${callpkg}::$sym"} =
	    $type eq '&' ? \&{"${pkg}::$sym"} :
	    $type eq '$' ? \${"${pkg}::$sym"} :
	    $type eq '@' ? \@{"${pkg}::$sym"} :
	    $type eq '%' ? \%{"${pkg}::$sym"} :
	    $type eq '*' ?  *{"${pkg}::$sym"} :
		    warn "Can't export symbol: $type$sym\n";
    }
};

sub import {
    local ($callpkg, $callfile, $callline) = caller($ExportLevel);
    my $pkg = shift;
    export $pkg, $callpkg, @_;
}

sub export_tags {
    my ($pkg) = caller;
    *tags = \%{"${pkg}::EXPORT_TAGS"};
    push(@{"${pkg}::EXPORT"},
	map {$tags{$_} ? @{$tags{$_}} : $_} @_ ? @_ : keys %tags);
}

sub require_version {
    my($self, $wanted) = @_;
    my $pkg = ref $self || $self;
    my $version = ${"${pkg}::VERSION"} || "(undef)";
    Carp::croak("$pkg $wanted required--this is only version $version")
		if $version < $wanted;
    $version;
}

1;
