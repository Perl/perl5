# Devel::DProf - a Perl code profiler
#  5apr95
#  Dean Roehrich
#
# changes/bugs fixed since 01mar95 version:
#  - record $pwd and build pathname for tmon.out
#      (so the profile doesn't get lost if the process chdir's)
# changes/bugs fixed since 03feb95 version:
#  - fixed some doc bugs
#  - added require 5.000
#  - added -w note to bugs section of pod
# changes/bugs fixed since 31dec94 version:
#  - podified
#

require 5.000;

=head1 NAME

Devel::DProf - a Perl code profiler

=head1 SYNOPSIS

	PERL5DB="use Devel::DProf;"
	export PERL5DB

	perl5 -d test.pl

=head1 DESCRIPTION

The Devel::DProf package is a Perl code profiler.  This will collect
information on the execution time of a Perl script and of the subs in that
script.  This information can be used to determine which subroutines are
using the most time and which subroutines are being called most often.  This
information can also be used to create an execution graph of the script,
showing subroutine relationships.

To use this package the PERL5DB environment variable must be set to the
following value:

	PERL5DB="use Devel::DProf;"
	export PERL5DB

To profile a Perl script run the perl interpreter with the B<-d> debugging
switch.  The profiler uses the debugging hooks.  So to profile script
"test.pl" the following command should be used:

	perl5 -d test.pl

When the script terminates the profiler will dump the profile information
to a file called I<tmon.out>.  The supplied I<dprofpp> tool can be used to
interpret the information which is in that profile.  The following command
will print the top 15 subroutines which used the most time:

	dprofpp

To print an execution graph of the subroutines in the script use the
following command:

	dprofpp -T

Consult the "dprofpp" manpage for other options.

=head1 BUGS

If perl5 is invoked with the B<-w> (warnings) flag then Devel::DProf will
cause a large quantity of warnings to be printed.

=head1 SEE ALSO

L<perl>, L<dprofpp>, times(2)

=cut

package DB;

# So Devel::DProf knows where to drop tmon.out.
chop($pwd = `pwd`);
$tmon = "$pwd/tmon.out";

# This sub is replaced by an XS version after the profiler is bootstrapped.
sub sub {
#	print "nonXS DBsub($sub)\n";
	$single = 0; # disable DB single-stepping
	if( wantarray ){
		@a = &$sub;
		@a;
	}
	else{
		$a = &$sub;
		$a;
	}
}

# This sub is needed during startup.
sub DB { 
#	print "nonXS DBDB\n";
}


require DynaLoader;
@Devel::DProf::ISA = qw(DynaLoader);

bootstrap Devel::DProf;

1;
