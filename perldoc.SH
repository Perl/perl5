case $CONFIG in
'')
	if test -f config.sh; then TOP=.;
	elif test -f ../config.sh; then TOP=..;
	elif test -f ../../config.sh; then TOP=../..;
	elif test -f ../../../config.sh; then TOP=../../..;
	elif test -f ../../../../config.sh; then TOP=../../../..;
	else
		echo "Can't find config.sh."; exit 1
	fi
	. $TOP/config.sh
	;;
esac
: This forces SH files to create target in same directory as SH file.
: This is so that make depend always knows where to find SH derivatives.
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
echo "Extracting perldoc (with variable substitutions)"
$spitshell >perldoc <<!GROK!THIS!
#!$binexp/perl
!GROK!THIS!

$spitshell >>perldoc <<'!NO!SUBS!'

#
# Perldoc revision #1 -- look up a piece of documentation in .pod format that
# is embedded in the perl installation tree.
#
# This is not to be confused with Tom Christianson's perlman, which is a
# man replacement, written in perl. This perldoc is strictly for reading
# the perl manuals, though it too is written in perl.
#
# Version 1.01:	Tue May 30 14:47:34 EDT 1995
#		Andy Dougherty  <doughera@lafcol.lafayette.edu>
#   -added pod documentation.
#   -added PATH searching.
#   -added searching pod/ subdirectory (mainly to pick up perlfunc.pod
#    and friends.

=head1 NAME

perldoc - Look up Perl documentation in pod format.

=head1 SYNOPSIS

B<perldoc> [B<-h>] PageName|ModuleName

=head1 DESCRIPTION

I<perldoc> looks up a piece of documentation in .pod format that is
embedded in the perl installation tree or in a perl script, and displays
it via pod2man | nroff -man | $PAGER.  This is primarily used for the
documentation for the perl library modules. 

Your system may also have man pages installed for those modules, in
which case you can probably just use the man(1) command.

=head1 OPTIONS

=over 5

=item B<-h> help

Prints out a brief help message.

=item B<PageName|ModuleName>

The item you want to look up.  Nested modules (such as C<File::Basename>)
are specified either as C<File::Basename> or C<File/Basename>.  You
may also give a descriptive name of a page, such as C<perlfunc>.

=back

=head1 ENVIRONMENT

Any switches in the C<PERLDOC> environment variable will be used before the 
command line arguments.  C<perldoc> also searches directories
specified by the C<PERL5LIB> (or C<PERLLIB> if C<PERL5LIB> is not
defined) and C<PATH> environment variables.
(The latter is so that embedded pods for executables, such as
C<perldoc> itself, are available.)

=head1 AUTHOR

Kenneth Albanowski <kjahds@kjahds.com>

Minor updates by Andy Dougherty <doughera@lafcol.lafayette.edu>

=head1 SEE ALSO

=head1 DIAGNOSTICS

=cut

if(@ARGV<1) {
	die <<EOF;
Usage: $0 [-h] PageName|ModuleName

We suggest you use "perldoc perldoc" to get aquainted 
with the system.
EOF
}

use Getopt::Std;

sub usage{
        warn "@_\n" if @_;
    die <<EOF;
perlman [-h] PageName|ModuleName...
    -h   Display this help message.
PageName|ModuleName...
         is the name of a piece of documentation that you want to look at. You 
         may either give a descriptive name of the page (as in the case of
         `perlfunc') or the name of a module, either like `Term::Info', 
         `Term/Info'.
         
Any switches in the PERLDOC environment variable will be used before the 
command line arguments.

EOF
}

use Text::ParseWords;

unshift(@ARGV,shellwords($ENV{"PERLDOC"}));

getopts("h") || usage;

usage if $opt_h;

$index = $opt_i;
@pages = @ARGV;

sub containspod {
	my($file) = @_;
	local($_);
	open(TEST,"<$file");
	while(<TEST>) {
		if(/^=head/) {
			close(TEST);
			return 1;
		}
	}
	close(TEST);
	return 0;
}

sub searchfor {
	my($s,@dirs) = @_;
	$s =~ s!::!/!g;
	# printf STDERR "looking for $s in @dirs\n";
	
	foreach $dir (@dirs) {
		if( -f "$dir/$s.pod") { return "$dir/$s.pod" }
		elsif( -f "$dir/$s.pm" and containspod("$dir/$s.pm"))
			{ return "$dir/$s.pm" }
		elsif( -f "$dir/$s" and containspod("$dir/$s"))
			{ return "$dir/$s" } 
		elsif( -f "$dir/pod/$s.pod") { return "$dir/pod/$s.pod" }
		elsif( -f "$dir/pod/$s" and containspod("$dir/pod/$s"))
			{ return "$dir/pod/$s" } 
	}
	return ();
}


$ENV{PAGER} ||= "more";

foreach (@pages) {
	print STDERR "Searching for $_\n";
	# We must look both in @INC for library modules and in PATH
	# for executables, like h2xs or perldoc itself.
	@searchdirs = @INC;
	push(@searchdirs, split(':', $ENV{'PATH'}) );
	@files= searchfor($_,@searchdirs);
	if( @files ) {
		print STDERR "Found as @files\n";
	} else {
		print STDERR "No documentation found for $_\n";
	}
	push(@found,@files);
}

$cmd=$filter="";

if( ! -t STDOUT ) { $opt_f = 1 }

$cmd = "pod2man - | nroff -man";
if( ! $opt_f ) { $filter = "|$ENV{PAGER}" };

open(OUT,"|$cmd$filter");
foreach (@found) {
	open(IN,"<$_");
	print OUT while <IN>;
	close(IN);
}
close(OUT);
!NO!SUBS!
chmod 755 perldoc
$eunicefix perldoc
