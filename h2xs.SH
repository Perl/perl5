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
echo "Extracting h2xs (with variable substitutions)"
$spitshell >h2xs <<!GROK!THIS!
#!$bin/perl
!GROK!THIS!

$spitshell >>h2xs <<'!NO!SUBS!'

=head1 NAME

h2xs - convert .h C header files to Perl extensions

=head1 SYNOPSIS

B<h2xs> [B<-Acfh>] [B<-n> module_name] [headerfile [extra_libraries]]

=head1 DESCRIPTION

I<h2xs> builds a Perl extension from any C header file.  The extension will
include functions which can be used to retrieve the value of any #define
statement which was in the C header.

The I<module_name> will be used for the name of the extension.  If
module_name is not supplied then the name of the header file will be used,
with the first character capitalized.

If the extension might need extra libraries, they should be included
here.  The extension Makefile.PL will take care of checking whether
the libraries actually exist and how they should be loaded.
The extra libraries should be specified in the form -lm -lposix, etc,
just as on the cc command line.  By default, the Makefile.PL will
search through the library path determined by Configure.  That path
can be augmented by including arguments of the form B<-L/another/library/path>
in the extra-libraries argument.

=head1 OPTIONS

=over 5

=item B<-n> I<module_name>

Specifies a name to be used for the extension, e.g., S<-n RPC::DCE>

=item B<-f>

Allows an extension to be created for a header even if that header is
not found in /usr/include.

=item B<-c>

Omit C<constant()> from the .xs file and corresponding specialised
C<AUTOLOAD> from the .pm file.

=item B<-A>

Omit all autoload facilities.  This is the same as B<-c> but also removes the
S<C<require AutoLoader>> statement from the .pm file.

=back

=head1 EXAMPLES


	# Default behavior, extension is Rusers
	h2xs rpcsvc/rusers

	# Same, but extension is RUSERS
	h2xs -n RUSERS rpcsvc/rusers

	# Extension is rpcsvc::rusers. Still finds <rpcsvc/rusers.h>
	h2xs rpcsvc::rusers

	# Extension is ONC::RPC.  Still finds <rpcsvc/rusers.h>
	h2xs -n ONC::RPC rpcsvc/rusers

	# Without constant() or AUTOLOAD
	h2xs -c rpcsvc/rusers

	# Creates templates for an extension named RPC
	h2xs -cfn RPC

	# Extension is ONC::RPC.
	h2xs -cfn ONC::RPC

	# Makefile.PL will look for library -lrpc in 
	# additional directory /opt/net/lib
	h2xs rpcsvc/rusers -L/opt/net/lib -lrpc


=head1 ENVIRONMENT

No environment variables are used.

=head1 AUTHOR

Larry Wall and others

=head1 SEE ALSO

L<perl>, L<ExtUtils::MakeMaker>, L<AutoLoader>

=head1 DIAGNOSTICS

The usual warnings if it can't read or write the files involved.

=cut


use Getopt::Std;

sub usage{
	warn "@_\n" if @_;
    die 'h2xs [-Acfh] [-n module_name] [headerfile [extra_libraries]]
    -f   Force creation of the extension even if the C header does not exist.
    -n   Specify a name to use for the extension (recommended).
    -c   Omit the constant() function and specialised AUTOLOAD from the XS file.
    -A   Omit all autoloading facilities (implies -c).
    -h   Display this help message
extra_libraries
         are any libraries that might be needed for loading the
         extension, e.g. -lm would try to link in the math library.
';
}


getopts("Acfhn:") || usage;

usage if $opt_h;
$opt_c = 1 if $opt_A;

$path_h    = shift;
$extralibs = "@ARGV";

usage "Must supply header file or module name\n"
	unless ($path_h or $opt_n);


if( $path_h ){
    $name = $path_h;
    if( $path_h =~ s#::#/#g && $opt_n ){
	warn "Nesting of headerfile ignored with -n\n";
    }
    $path_h .= ".h" unless $path_h =~ /\.h$/;
    $path_h = "/usr/include/$path_h" unless $path_h =~ m#^[./]#;
    die "Can't find $path_h\n" if ( ! $opt_f && ! -f $path_h );

    # Scan the header file (we should deal with nested header files)
    # Record the names of simple #define constants into const_names
    # Function prototypes are not (currently) processed.
    open(CH, "<$path_h") || die "Can't open $path_h: $!\n";
    while (<CH>) {
	if (/^#[ \t]*define\s+(\w+)\b\s*[^("]/) {
	    $_ = $1;
	    next if /^_.*_h_*$/i; # special case, but for what?
	    $const_names{$_}++;
	}
    }
    close(CH);
    @const_names = sort keys %const_names;
}


$module = $opt_n || do {
	$name =~ s/\.h$//;
	if( $name !~ /::/ ){
		$name =~ s#^.*/##;
		$name = "\u$name";
	}
	$name;
};

chdir 'ext' if -d 'ext';

if( $module =~ /::/ ){
	$nested = 1;
	@modparts = split(/::/,$module);
	$modfname = $modparts[-1];
	$modpname = join('/',@modparts);
}
else {
	$nested = 0;
	@modparts = ();
	$modfname = $modpname = $module;
}


die "Won't overwrite existing ext/$modpname\n" if -e $modpname;
# quick hack, should really loop over @modparts
mkdir($modparts[0], 0777) if $nested;
mkdir($modpname, 0777);
chdir($modpname) || die "Can't chdir ext/$modpname: $!\n";

open(XS, ">$modfname.xs") || die "Can't create ext/$modpname/$modfname.xs: $!\n";
open(PM, ">$modfname.pm") || die "Can't create ext/$modpname/$modfname.pm: $!\n";

$" = "\n\t";
warn "Writing ext/$modpname/$modfname.pm\n";

print PM <<"END";
package $module;

require Exporter;
require DynaLoader;
END

if( ! $opt_A ){
	print PM <<"END";
require AutoLoader;
END
}

if( $opt_c && ! $opt_A ){
	# we won't have our own AUTOLOAD(), so we'll inherit it.
	print PM <<"END";

\@ISA = qw(Exporter AutoLoader DynaLoader);
END
}
else{
	# 1) we have our own AUTOLOAD(), so don't need to inherit it.
	# or
	# 2) we don't want autoloading mentioned.
	print PM <<"END";

\@ISA = qw(Exporter DynaLoader);
END
}

print PM<<"END";
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
\@EXPORT = qw(
	@const_names
);
# Other items we are prepared to export if requested
\@EXPORT_OK = qw(
);

END

print PM <<"END" unless $opt_c;
sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    # NOTE: THIS AUTOLOAD FUNCTION IS FLAWED (but is the best we can do for now).
    # Avoid old-style ``&CONST'' usage. Either remove the ``&'' or add ``()''.
    if (\@_ > 0) {
	\$AutoLoader::AUTOLOAD = \$AUTOLOAD;
	goto &AutoLoader::AUTOLOAD;
    }
    local(\$constname);
    (\$constname = \$AUTOLOAD) =~ s/.*:://;
    \$val = constant(\$constname, \@_ ? \$_[0] : 0);
    if (\$! != 0) {
	if (\$! =~ /Invalid/) {
	    \$AutoLoader::AUTOLOAD = \$AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    (\$pack,\$file,\$line) = caller;
	    die "Your vendor has not defined $module macro \$constname, used at \$file line \$line.\n";
	}
    }
    eval "sub \$AUTOLOAD { \$val }";
    goto &\$AUTOLOAD;
}

END

print PM <<"END";
bootstrap $module;

# Preloaded methods go here.

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__
END

close PM;


warn "Writing ext/$modpname/$modfname.xs\n";

print XS <<"END";
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

END
if( $path_h ){
	my($h) = $path_h;
	$h =~ s#^/usr/include/##;
print XS <<"END";
#include <$h>

END
}

if( ! $opt_c ){
print XS <<"END";
static int
not_here(s)
char *s;
{
    croak("$module::%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
END

my(@AZ, @az, @under);

foreach(@const_names){
    @AZ = 'A' .. 'Z' if !@AZ && /^[A-Z]/;
    @az = 'a' .. 'z' if !@az && /^[a-z]/;
    @under = '_'  if !@under && /^_/;
}

foreach $letter (@AZ, @az, @under) {

    last if $letter eq 'a' && !@const_names;

    print XS "    case '$letter':\n";
    my($name);
    while (substr($const_names[0],0,1) eq $letter) {
	$name = shift(@const_names);
	print XS <<"END";
	if (strEQ(name, "$name"))
#ifdef $name
	    return $name;
#else
	    goto not_there;
#endif
END
    }
    print XS <<"END";
	break;
END
}
print XS <<"END";
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

END
}

# Now switch from C to XS by issuing the first MODULE declaration:
print XS <<"END";

MODULE = $module		PACKAGE = $module

END

# If a constant() function was written then output a corresponding
# XS declaration:
print XS <<"END" unless $opt_c;

double
constant(name,arg)
	char *		name
	int		arg

END

close XS;


warn "Writing ext/$modpname/Makefile.PL\n";
open(PL, ">Makefile.PL") || die "Can't create ext/$modpname/Makefile.PL: $!\n";

print PL <<'END';
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
END
print PL "WriteMakefile(\n";
print PL "    'NAME'	=> '$module',\n";
print PL "    'VERSION'	=> '0.1',\n";
print PL "    'LIBS'	=> ['$extralibs'],   # e.g., '-lm' \n";
print PL "    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' \n";
print PL "    'INC'	=> '',     # e.g., '-I/usr/include/other' \n";
print PL ");\n";


system '/bin/ls > MANIFEST';
!NO!SUBS!
chmod 755 h2xs
$eunicefix h2xs
