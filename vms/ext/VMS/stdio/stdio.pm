#   VMS::stdio - VMS extensions to Perl's stdio calls
#
#   Author:  Charles Bailey  bailey@genetics.upenn.edu
#   Version: 1.0
#   Revised: 29-Nov-1994
#
#   Revision History:
#   1.0  29-Nov-1994  Charles Bailey  bailey@genetics.upenn.edu
#     original version
#   1.1  09-Mar-1995  Charles Bailey  bailey@genetics.upenn.edu
#     changed calling sequence to return FH/undef - like POSIX::open
#     added fgetname and tmpnam

=head1 NAME

VMS::stdio

=head1 SYNOPSIS

use VMS::stdio;
$name = fgetname(FH);
$uniquename = &tmpnam;
$fh = vmsfopen("my.file","rfm=var","alq=100",...) or die $!;

=head1 DESCRIPTION

This package gives Perl scripts access to VMS extensions to the
C stdio routines, such as optional arguments to C<fopen()>.
The specific routines are described below.

=head2 fgetname

The C<fgetname> function returns the file specification associated
with a Perl FileHandle.  If an error occurs, it returns C<undef>.

=head2 tmpnam

The C<tmpnam> function returns a unique string which can be used
as a filename when creating temporary files.  If, for some
reason, it is unable to generate a name, it returns C<undef>.

=head2 vmsfopen

The C<vmsfopen> function provides access to the VMS CRTL
C<fopen()> function.  It is similar to the built-in Perl C<open>
function (see L<perlfunc> for a complete description), but will
only open normal files; it cannot open pipes or duplicate
existing FileHandles.  Up to 8 optional arguments may follow the
file name.  These arguments should be strings which specify
optional file characteristics as allowed by the CRTL C<fopen()>
routine. (See the CRTL reference manual for details.)

You can use the FileHandle returned by C<vmsfopen> just as you
would any other Perl FileHandle.

C<vmsfopen> is a temporary solution to problems which arise in
handling VMS-specific file formats; in the long term, we hope to
provide more transparent access to VMS file I/O through routines
which replace standard Perl C<open> function, or through tied
FileHandles.  When this becomes possible, C<vmsfopen> may be
replaced.

=head1 REVISION

This document was last revised on 09-Mar-1995, for Perl 5.001.

=cut

package VMS::stdio;

require DynaLoader;
require Exporter;
 
@ISA = qw( Exporter DynaLoader);
@EXPORT = qw( &fgetname &tmpfile &tmpnam &vmsfopen );

bootstrap VMS::stdio;
1;
