package AutoLoader;
use Carp;
$DB::sub = $DB::sub;	# Avoid warning

=head1 NAME

AutoLoader - load functions only on demand

=head1 SYNOPSIS

    package FOOBAR;
    use Exporter;
    use AutoLoader;
    @ISA = (Exporter, AutoLoader);

=head1 DESCRIPTION

This module tells its users that functions in the FOOBAR package are
to be autoloaded from F<auto/$AUTOLOAD.al>.  See
L<perlsub/"Autoloading"> and L<AutoSplit>.

=head2 __END__

The module using the autoloader should have the special marker C<__END__>
prior to the actual subroutine declarations. All code that is before the
marker will be loaded and compiled when the module is used. At the marker,
perl will cease reading and parsing. See also the B<AutoSplit> module, a
utility that automatically splits a module into a collection of files for
autoloading.

When a subroutine not yet in memory is called, the C<AUTOLOAD> function
attempts to locate it in a directory relative to the location of the module
file itself. As an example, assume F<POSIX.pm> is located in 
F</usr/local/lib/perl5/POSIX.pm>. The autoloader will look for perl
subroutines for this package in F</usr/local/lib/perl5/auto/POSIX/*.al>.
The C<.al> file is named using the subroutine name, sans package.

=head2 Package Lexicals

Package lexicals declared with C<my> in the main block of a package using
the B<AutoLoader> will not be visible to auto-loaded functions, due to the
fact that the given scope ends at the C<__END__> marker. A module using such
variables as package globals will not work properly under the B<AutoLoader>.

The C<vars> pragma (see L<perlmod/"vars">) may be used in such situations
as an alternative to explicitly qualifying all globals with the package
namespace. Variables pre-declared with this pragma will be visible to any
autoloaded routines (but will not be invisible outside the package,
unfortunately).

=head2 AutoLoader vs. SelfLoader

The B<AutoLoader> is a counterpart to the B<SelfLoader> module. Both delay
the loading of subroutines, but the B<SelfLoader> accomplishes the goal via
the C<__DATA__> marker rather than C<__END__>. While this avoids the use of
a hierarchy of disk files and the associated open/close for each routine
loaded, the B<SelfLoader> suffers a disadvantage in the one-time parsing of
the lines after C<__DATA__>, after which routines are cached. B<SelfLoader>
can also handle multiple packages in a file.

B<AutoLoader> only reads code as it is requested, and in many cases should be
faster, but requires a machanism like B<AutoSplit> be used to create the
individual files.

=head1 CAVEAT

On systems with restrictions on file name length, the file corresponding to a
subroutine may have a shorter name that the routine itself. This can lead to
conflicting file names. The I<AutoSplit> package warns of these potential
conflicts when used to split a module.

=cut

AUTOLOAD {
    my $name = "auto/$AUTOLOAD.al";
    $name =~ s#::#/#g;
    eval {require $name};
    if ($@) {
	# The load might just have failed because the filename was too
	# long for some old SVR3 systems which treat long names as errors.
	# If we can succesfully truncate a long name then it's worth a go.
	# There is a slight risk that we could pick up the wrong file here
	# but autosplit should have warned about that when splitting.
	if ($name =~ s/(\w{12,})\.al$/substr($1,0,11).".al"/e){
	    eval {require $name};
	}
	elsif ($AUTOLOAD =~ /::DESTROY$/) {
	    # eval "sub $AUTOLOAD {}";
	    *$AUTOLOAD = sub {};
	}
	if ($@){
	    $@ =~ s/ at .*\n//;
	    croak $@;
	}
    }
    $DB::sub = $AUTOLOAD;	# Now debugger know where we are.
    goto &$AUTOLOAD;
}
                            
sub import {
    my ($callclass, $callfile, $callline,$path,$callpack) = caller(0);
    ($callpack = $callclass) =~ s#::#/#;
    # Try to find the autosplit index file.  Eg., if the call package
    # is POSIX, then $INC{POSIX.pm} is something like
    # '/usr/local/lib/perl5/POSIX.pm', and the autosplit index file is in
    # '/usr/local/lib/perl5/auto/POSIX/autosplit.ix', so we require that.
    #
    # However, if @INC is a relative path, this might not work.  If,
    # for example, @INC = ('lib'), then
    # $INC{POSIX.pm} is 'lib/POSIX.pm', and we want to require
    # 'auto/POSIX/autosplit.ix' (without the leading 'lib').
    #
    if (defined($path = $INC{$callpack . '.pm'})) {
	# Try absolute path name.
	$path =~ s#^(.*)$callpack\.pm$#$1auto/$callpack/autosplit.ix#;
	eval { require $path; };
	# If that failed, try relative path with normal @INC searching.
	if ($@) {
	    $path ="auto/$callpack/autosplit.ix";
	    eval { require $path; };
	}
	carp $@ if ($@);  
    } 
}

1;
